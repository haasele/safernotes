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
import 'dart:convert';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:easy_localization/easy_localization.dart';
import 'package:local_session_timeout/local_session_timeout.dart';

// Project imports:
import 'package:safenotes/data/database_handler.dart';
import 'package:safenotes/data/preference_and_config.dart';
import 'package:safenotes/dialogs/delete_confirmation.dart';
import 'package:safenotes/models/safenote.dart';
import 'package:safenotes/services/text_note_autosave.dart';
import 'package:safenotes/utils/notes_color.dart';
import 'package:safenotes/utils/text_direction_util.dart';
import 'package:safenotes/widgets/attachment_preview.dart';
import 'package:safenotes/widgets/markdown_editor.dart';
import 'package:safenotes/models/attachment.dart';

class NoteDetailPage extends StatefulWidget {
  final int noteId;
  final int noteIndex;
  final StreamController<SessionState> sessionStateStream;

  const NoteDetailPage({
    Key? key,
    required this.noteId,
    this.noteIndex = 0,
    required this.sessionStateStream,
  }) : super(key: key);

  @override
  NoteDetailPageState createState() => NoteDetailPageState();
}

class NoteDetailPageState extends State<NoteDetailPage> {
  late SafeNote note;
  bool isLoading = false;

  GlobalKey<MarkdownNoteEditorState> _editorKey =
      GlobalKey<MarkdownNoteEditorState>();
  TextEditingController? _titleController;
  TextNoteAutosaveController? _autosave;
  String _bodyDescription = '';
  String _bodyContentFormat = 'plain';

  @override
  void initState() {
    super.initState();
    refreshNote();
  }

  @override
  void dispose() {
    _titleController?.removeListener(_scheduleDetailAutosave);
    _titleController?.dispose();
    _autosave?.dispose();
    super.dispose();
  }

  Future<void> refreshNote() async {
    setState(() => isLoading = true);
    note = await NotesDatabase.instance.decryptReadNote(widget.noteId);
    _titleController?.removeListener(_scheduleDetailAutosave);
    _titleController?.dispose();
    _autosave?.dispose();

    _autosave = TextNoteAutosaveController(
      seed: note,
      onPersisted: (saved) {
        if (mounted) setState(() => note = saved);
      },
    );
    _bodyDescription = note.description;
    _bodyContentFormat = note.contentFormat;
    _titleController = TextEditingController(
      text: note.title == ' ' ? '' : note.title,
    );
    _titleController!.addListener(_scheduleDetailAutosave);

    _editorKey = GlobalKey<MarkdownNoteEditorState>();

    setState(() => isLoading = false);
  }

  void _scheduleDetailAutosave() {
    if (!mounted || _autosave == null || _titleController == null) return;
    if (note.noteType != 'text') return;

    final body = _editorKey.currentState != null
        ? _editorKey.currentState!.getSerializedContent()
        : _bodyDescription;

    _autosave!.scheduleSave(
      titleUi: _titleController!.text,
      body: body,
      noteType: note.noteType,
      contentFormat: _bodyContentFormat,
      onError: (e, _) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save note: $e')),
        );
      },
    );
  }

  void _onBodyChanged(String serialized) {
    _bodyDescription = serialized;
    _bodyContentFormat = 'document';
    _scheduleDetailAutosave();
  }

  Color? _noteColor(BuildContext context) {
    if (isLoading) return null;
    return NotesColor.getNoteColor(
      notIndex: widget.noteIndex,
      context: context,
      fixedColorIndex: note.colorIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = _noteColor(context);
    return Scaffold(
      backgroundColor: bg,
      appBar: _appBar(context, bg),
      body: _body(context),
    );
  }

  PreferredSizeWidget _appBar(BuildContext context, Color? bg) {
    return AppBar(
      backgroundColor: bg ?? Theme.of(context).appBarTheme.backgroundColor,
      title: isLoading ? Text('Loading...'.tr()) : null,
      actions: isLoading ? null : [deleteButton()],
    );
  }

  Widget _body(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (note.noteType == 'text' && _titleController != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextFormField(
                controller: _titleController,
                maxLines: 2,
                textDirection: getTextDirecton(_titleController!.text),
                enableIMEPersonalizedLearning:
                    !PreferencesStorage.keyboardIncognito,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Title'.tr(),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SelectableText(
                note.title,
                textDirection: getTextDirecton(note.title),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              DateFormat.yMMMd().format(note.createdTime),
              textDirection: getTextDirecton(note.title),
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (note.noteType) {
      case 'audio':
      case 'image':
      case 'drawing':
        return _buildAttachmentContent();
      case 'checklist':
        return _buildChecklistContent();
      case 'text':
      default:
        return _buildTextContent();
    }
  }

  Widget _buildTextContent() {
    return MarkdownNoteEditor(
      key: _editorKey,
      initialContent: _bodyDescription,
      contentFormat: _bodyContentFormat,
      readOnly: false,
      onChanged: _onBodyChanged,
    );
  }

  Widget _buildAttachmentContent() {
    return FutureBuilder<List<NoteAttachment>>(
      future: NotesDatabase.instance.getAttachmentsForNote(widget.noteId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final attachments = snapshot.data!;
        if (attachments.isEmpty) {
          return Center(
            child: Text(
              note.description,
              style: const TextStyle(fontSize: 18),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: attachments.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) => buildAttachmentPreview(attachments[i]),
        );
      },
    );
  }

  Widget _buildChecklistContent() {
    List<Map<String, dynamic>> items;
    try {
      final list = jsonDecode(note.description) as List;
      items = list
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      items = [];
    }

    if (items.isEmpty) {
      return Center(
        child: Text(note.description, style: const TextStyle(fontSize: 18)),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final checked = item['checked'] as bool? ?? false;
        final text = item['text'] as String? ?? '';
        final cs = Theme.of(context).colorScheme;

        return ListTile(
          leading: Icon(
            checked ? Icons.check_box : Icons.check_box_outline_blank,
            color: checked ? cs.primary : cs.outline,
          ),
          title: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              decoration: checked ? TextDecoration.lineThrough : null,
              color: checked ? cs.outline : cs.onSurface,
            ),
          ),
        );
      },
    );
  }

  Widget deleteButton() {
    return IconButton(
      icon: const Icon(Icons.delete),
      onPressed: () async {
        await confirmAndDeleteDialog(context);
      },
    );
  }

  Future<void> confirmAndDeleteDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext contextChild) {
        return DeleteConfirmationDialog(
          callback: () async {
            var childNavigator = Navigator.of(contextChild);
            var navigator = Navigator.of(context);
            await NotesDatabase.instance.delete(widget.noteId);
            childNavigator.pop();
            navigator.pop();
          },
        );
      },
    );
  }
}
