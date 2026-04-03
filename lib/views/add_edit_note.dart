/*
* Copyright (C) Keshav Priyadarshi and others - All Rights Reserved.
*
* SPDX-License-Identifier: GPL-3.0-or-later
* You may use, distribute and modify this code under the
* terms of the GPL-3.0+ license.
*
* You should have received a copy of the GNU General Public License v3.0 with
* this file. If not, please visit https://www.gnu.org/licenses/gpl-3.0.html
*
* See https://safenotes.dev for support or download.
*/

// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:easy_localization/easy_localization.dart';
import 'package:local_session_timeout/local_session_timeout.dart';

// Project imports:
import 'package:safenotes/models/editor_state.dart';
import 'package:safenotes/models/safenote.dart';
import 'package:safenotes/utils/notes_color.dart';
import 'package:safenotes/widgets/markdown_editor.dart';
import 'package:safenotes/widgets/note_widget.dart';

class AddEditNotePage extends StatefulWidget {
  final StreamController<SessionState> sessionStateStream;
  final SafeNote? note;
  final int noteIndex;
  final String noteType;

  const AddEditNotePage({
    Key? key,
    this.note,
    required this.sessionStateStream,
    this.noteIndex = 0,
    this.noteType = 'text',
  }) : super(key: key);

  @override
  AddEditNotePageState createState() => AddEditNotePageState();
}

class AddEditNotePageState extends State<AddEditNotePage> {
  final _formKey = GlobalKey<FormState>();
  final _editorKey = GlobalKey<MarkdownNoteEditorState>();
  late final TextEditingController _titleController;

  late String description;
  late String contentFormat;
  Timer? _descriptionDebounce;

  /// When true, [PopScope] must not auto-save (explicit Save already persisted).
  bool _skipPopAutoSave = false;

  @override
  void initState() {
    super.initState();
    var t = widget.note?.title ?? '';
    description = widget.note?.description ?? '';
    contentFormat = widget.note?.contentFormat ?? 'plain';
    t = t == ' ' ? '' : t;
    description = description == ' ' ? '' : description;
    _titleController = TextEditingController(text: t);
    NoteEditorState.setSaveAttempted(false);
    NoteEditorState.setState(
      widget.note,
      t,
      description,
      contentFormat: contentFormat,
      noteType: widget.note?.noteType ?? widget.noteType,
    );
  }

  @override
  void dispose() {
    _descriptionDebounce?.cancel();
    _titleController.dispose();
    super.dispose();
  }

  String get title => _titleController.text;

  Color? _noteColor(BuildContext context) {
    if (widget.note == null) return null;
    return NotesColor.getNoteColor(
      notIndex: widget.noteIndex,
      context: context,
      fixedColorIndex: widget.note?.colorIndex,
    );
  }

  void _syncNoteEditorFromTitle() {
    NoteEditorState.setState(
      widget.note,
      _titleController.text,
      description,
      contentFormat: 'document',
      noteType: widget.note?.noteType ?? widget.noteType,
    );
  }

  void _onDescriptionChanged(String newDescription) {
    description = newDescription;
    contentFormat = 'document';
    NoteEditorState.setState(
      widget.note,
      _titleController.text,
      description,
      contentFormat: 'document',
      noteType: widget.note?.noteType ?? widget.noteType,
    );
    _descriptionDebounce?.cancel();
    _descriptionDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() {});
    });
  }

  /// Updates static editor state only — no [setState] (keeps AppFlowy subtree stable).
  void _onTitleChanged(String _) {
    _syncNoteEditorFromTitle();
  }

  @override
  Widget build(BuildContext context) {
    final bg = _noteColor(context);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop || _skipPopAutoSave) return;
        if (isNoteNewOrContentChanged()) {
          NoteEditorState.setState(
            widget.note,
            _titleController.text,
            _editorKey.currentState?.getSerializedContent() ?? description,
            contentFormat: 'document',
            noteType: widget.note?.noteType ?? widget.noteType,
          );
          NoteEditorState().addOrUpdateNote();
        }
      },
      child: Scaffold(
        backgroundColor: bg,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: bg ?? Theme.of(context).appBarTheme.backgroundColor,
          actions: [
            ListenableBuilder(
              listenable: _titleController,
              builder: (context, _) => buildButton(),
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Form(
      key: _formKey,
      child: NoteFormWidget(
        titleController: _titleController,
        description: description,
        contentFormat: contentFormat,
        sessionStateStream: widget.sessionStateStream,
        editorKey: _editorKey,
        onChangedTitle: _onTitleChanged,
        onChangedDescription: _onDescriptionChanged,
      ),
    );
  }

  Widget buildButton() {
    final isFormValid =
        title.isNotEmpty || NoteEditorState.description.isNotEmpty;
    const double buttonFontSize = 17.0;
    final String buttonText = 'Save'.tr();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        onPressed: isFormValid ? onSaveCallback : null,
        child: Text(
          buttonText,
          style: const TextStyle(
            fontSize: buttonFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> onSaveCallback() async {
    final navigator = Navigator.of(context);
    NoteEditorState.setState(
      widget.note,
      _titleController.text,
      _editorKey.currentState?.getSerializedContent() ?? description,
      contentFormat: 'document',
      noteType: widget.note?.noteType ?? widget.noteType,
    );
    await NoteEditorState().addOrUpdateNote();
    _skipPopAutoSave = true;
    if (mounted) navigator.pop();
  }

  bool isNoteNewOrContentChanged() {
    final body =
        _editorKey.currentState?.getSerializedContent() ?? description;
    if (widget.note == null) {
      if (title.isNotEmpty || body.isNotEmpty) return true;
    } else {
      if (widget.note?.title != title && title != '' ||
          widget.note?.description != body && body != '') {
        return true;
      }
    }
    return false;
  }
}
