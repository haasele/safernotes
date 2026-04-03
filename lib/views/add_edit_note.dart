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
import 'package:safenotes/services/text_note_autosave.dart';
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
  late final TextNoteAutosaveController _autosave;

  late String description;
  late String contentFormat;

  /// When true, [PopScope] must not flush again (explicit close already ran).
  bool _skipPopAutoSave = false;

  @override
  void initState() {
    super.initState();
    var t = widget.note?.title ?? '';
    description = widget.note?.description ?? '';
    contentFormat = widget.note?.contentFormat ?? 'document';
    t = t == ' ' ? '' : t;
    description = description == ' ' ? '' : description;
    _titleController = TextEditingController(text: t);
    _titleController.addListener(_scheduleAutosave);
    _autosave = TextNoteAutosaveController(seed: widget.note);
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
    _titleController.removeListener(_scheduleAutosave);
    _titleController.dispose();
    _autosave.dispose();
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

  void _scheduleAutosave() {
    if (!mounted) return;
    final body =
        _editorKey.currentState?.getSerializedContent() ?? description;
    description = body;
    contentFormat = 'document';
    _autosave.scheduleSave(
      titleUi: _titleController.text,
      body: body,
      noteType: widget.note?.noteType ?? widget.noteType,
      contentFormat: 'document',
      onError: _onAutosaveError,
    );
  }

  void _onAutosaveError(Object e, StackTrace _) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not save note: $e')),
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
    _scheduleAutosave();
  }

  void _onTitleChanged(String _) {
    _syncNoteEditorFromTitle();
    _scheduleAutosave();
  }

  Future<void> _flushAndPop() async {
    final navigator = Navigator.of(context);
    final body =
        _editorKey.currentState?.getSerializedContent() ?? description;
    await _autosave.flush(
      titleUi: _titleController.text,
      body: body,
      noteType: widget.note?.noteType ?? widget.noteType,
      contentFormat: 'document',
      onError: _onAutosaveError,
    );
    _skipPopAutoSave = true;
    if (mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final bg = _noteColor(context);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop || _skipPopAutoSave) return;
        final body =
            _editorKey.currentState?.getSerializedContent() ?? description;
        unawaited(
          _autosave.flush(
            titleUi: _titleController.text,
            body: body,
            noteType: widget.note?.noteType ?? widget.noteType,
            contentFormat: 'document',
            onError: _onAutosaveError,
          ),
        );
      },
      child: Scaffold(
        backgroundColor: bg,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: bg ?? Theme.of(context).appBarTheme.backgroundColor,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: TextButton(
                onPressed: _flushAndPop,
                child: Text(
                  'Done'.tr(),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
}
