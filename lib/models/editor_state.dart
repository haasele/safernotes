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

// Project imports:
import 'package:safenotes/data/database_handler.dart';
import 'package:safenotes/models/safenote.dart';

class NoteEditorState {
  static SafeNote? original;
  static String title = '';
  static String description = '';
  static String contentFormat = 'plain';
  static String noteType = 'text';

  static bool wasNoteSaveAttempted = false;
  static setSaveAttempted(bool flag) => wasNoteSaveAttempted = flag;

  static setState(
    SafeNote? note,
    String titleNew,
    String descriptionNew, {
    String? contentFormat,
    String? noteType,
  }) {
    original = note;
    title = titleNew;
    description = descriptionNew;
    if (contentFormat != null) NoteEditorState.contentFormat = contentFormat;
    if (noteType != null) NoteEditorState.noteType = noteType;
    wasNoteSaveAttempted = false;
  }

  static destroyValue() {
    original = null;
    title = description = '';
    contentFormat = 'plain';
    noteType = 'text';
    wasNoteSaveAttempted = false;
  }

  Future<void> handleUngracefulNoteExit() async {
    if (wasNoteSaveAttempted == false &&
        (title.isNotEmpty || description.isNotEmpty)) {
      await addOrUpdateNote();
    }
  }

  Future<void> addOrUpdateNote() async {
    if (title.isNotEmpty || description.isNotEmpty) {
      title = title.isEmpty ? ' ' : title;
      description = description.isEmpty ? ' ' : description;

      final isUpdating = original != null;
      if (isUpdating) {
        if (original!.title != title || original!.description != description) {
          await updateNote();
        }
      } else {
        await addNote();
      }
    }
    destroyValue();
  }

  Future addNote() async {
    final note = SafeNote(
      title: title,
      description: description,
      createdTime: DateTime.now(),
      noteType: noteType,
      contentFormat: contentFormat,
    );
    await NotesDatabase.instance.encryptAndStore(note);
  }

  Future updateNote() async {
    final note = original!.copy(
      title: title,
      description: description,
      createdTime: DateTime.now(),
      contentFormat: contentFormat,
      noteType: noteType.isNotEmpty ? noteType : null,
    );
    await NotesDatabase.instance.encryptAndUpdate(note);
  }
}
