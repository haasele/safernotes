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

  late String title;
  late String description;
  late String contentFormat;

  @override
  void initState() {
    super.initState();
    title = widget.note?.title ?? '';
    description = widget.note?.description ?? '';
    contentFormat = widget.note?.contentFormat ?? 'plain';
    title = title == ' ' ? '' : title;
    description = description == ' ' ? '' : description;
    NoteEditorState.setSaveAttempted(false);
  }

  Color? _noteColor(BuildContext context) {
    if (widget.note == null) return null;
    return NotesColor.getNoteColor(
      notIndex: widget.noteIndex,
      context: context,
      fixedColorIndex: widget.note?.colorIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = _noteColor(context);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && isNoteNewOrContentChanged()) {
          NoteEditorState().addOrUpdateNote();
        }
      },
      child: Scaffold(
        backgroundColor: bg,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: bg ?? Theme.of(context).appBarTheme.backgroundColor,
          actions: [buildButton()],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Form(
      key: _formKey,
      child: NoteFormWidget(
        title: title,
        description: description,
        contentFormat: contentFormat,
        sessionStateStream: widget.sessionStateStream,
        editorKey: _editorKey,
        onChangedTitle: (title) => setState(() {
          this.title = title;
          NoteEditorState.setState(
            widget.note, this.title, description,
            contentFormat: 'document',
            noteType: widget.note?.noteType ?? widget.noteType,
          );
        }),
        onChangedDescription: (description) => setState(() {
          this.description = description;
          contentFormat = 'document';
          NoteEditorState.setState(
            widget.note, title, this.description,
            contentFormat: 'document',
            noteType: widget.note?.noteType ?? widget.noteType,
          );
        }),
      ),
    );
  }

  Widget buildButton() {
    final isFormValid = title.isNotEmpty || description.isNotEmpty;
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
    var navigator = Navigator.of(context);
    await NoteEditorState().addOrUpdateNote();
    navigator.pop();
  }

  bool isNoteNewOrContentChanged() {
    if (widget.note == null) {
      if (title.isNotEmpty || description.isNotEmpty) return true;
    } else {
      if (widget.note?.title != title && title != '' ||
          widget.note?.description != description && description != '') {
        return true;
      }
    }
    return false;
  }
}
