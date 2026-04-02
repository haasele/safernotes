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
import 'package:safenotes/dialogs/delete_confirmation.dart';
import 'package:safenotes/models/safenote.dart';
import 'package:safenotes/routes/route_generator.dart';
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

  @override
  void initState() {
    super.initState();
    refreshNote();
  }

  Future refreshNote() async {
    setState(() => isLoading = true);
    note = await NotesDatabase.instance.decryptReadNote(widget.noteId);
    setState(() => isLoading = false);
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
      actions: isLoading ? null : [editButton(), deleteButton()],
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
    if (note.contentFormat == 'document') {
      return MarkdownNoteEditor(
        initialContent: note.description,
        contentFormat: note.contentFormat,
        readOnly: true,
      );
    }
    return ListView(
      children: [
        SelectableText(
          note.description,
          textDirection: getTextDirecton(note.description),
          style: const TextStyle(fontSize: 18),
        ),
      ],
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
          separatorBuilder: (_, __) => const SizedBox(height: 12),
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

  Widget editButton() {
    return IconButton(
      icon: const Icon(Icons.edit_outlined),
      onPressed: () async {
        if (isLoading) return;
        await Navigator.pushNamed(
          context,
          '/editnote',
          arguments: AddEditNoteArguments(
            sessionStream: widget.sessionStateStream,
            note: note,
            noteIndex: widget.noteIndex,
          ),
        );
        refreshNote();
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

  confirmAndDeleteDialog(BuildContext context) async {
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
