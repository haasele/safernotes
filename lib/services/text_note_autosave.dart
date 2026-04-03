/*
* Copyright (C) Keshav Priyadarshi and others - All Rights Reserved.
*
* SPDX-License-Identifier: GPL-3.0-or-later
*/

import 'dart:async';

import 'package:safenotes/data/database_handler.dart';
import 'package:safenotes/models/editor_state.dart';
import 'package:safenotes/models/safenote.dart';
import 'package:safenotes/utils/document_utils.dart';

/// Debounced encrypt-and-store/update for text notes while keeping a stable DB id.
class TextNoteAutosaveController {
  TextNoteAutosaveController({
    SafeNote? seed,
    this.onPersisted,
  }) : _working = seed {
    if (seed != null) {
      _lastTitleDb = _toDbTitle(seed.title == ' ' ? '' : seed.title);
      _lastBodyDb = seed.description.isEmpty ? ' ' : seed.description;
    }
  }

  /// Called after a successful write (optional UI sync).
  final void Function(SafeNote note)? onPersisted;

  SafeNote? _working;
  String _lastTitleDb = '';
  String _lastBodyDb = '';
  Timer? _debounce;

  SafeNote? get workingNote => _working;

  static String _toDbTitle(String titleUi) =>
      titleUi.trim().isEmpty ? ' ' : titleUi.trim();

  static String _toDbBody(String body) =>
      body.trim().isEmpty ? ' ' : body;

  /// Skip first insert when the user has not entered a title and the body is still the default blank doc.
  bool _shouldSkipInsertForEmptyDraft(String titleUi, String body) {
    if (titleUi.trim().isNotEmpty) return false;
    final blank = serializedBlankDocument();
    return body == blank || body.trim().isEmpty;
  }

  void scheduleSave({
    required String titleUi,
    required String body,
    required String noteType,
    String contentFormat = 'document',
    Duration debounce = const Duration(milliseconds: 800),
    void Function(Object error, StackTrace stack)? onError,
  }) {
    _debounce?.cancel();
    _debounce = Timer(debounce, () {
      flush(
        titleUi: titleUi,
        body: body,
        noteType: noteType,
        contentFormat: contentFormat,
        onError: onError,
      );
    });
  }

  Future<void> flush({
    required String titleUi,
    required String body,
    required String noteType,
    String contentFormat = 'document',
    void Function(Object error, StackTrace stack)? onError,
  }) async {
    _debounce?.cancel();
    final titleDb = _toDbTitle(titleUi);
    final bodyDb = _toDbBody(body);

    if (_working?.id == null && _shouldSkipInsertForEmptyDraft(titleUi, body)) {
      return;
    }

    if (titleDb == ' ' && bodyDb == ' ' && _working?.id == null) {
      return;
    }

    try {
      if (_working?.id != null) {
        if (_lastTitleDb == titleDb && _lastBodyDb == bodyDb) return;
        final updated = _working!.copy(
          title: titleDb,
          description: bodyDb,
          createdTime: DateTime.now(),
          contentFormat: contentFormat,
          noteType: noteType.isNotEmpty ? noteType : null,
        );
        await NotesDatabase.instance.encryptAndUpdate(updated);
        _working = updated;
      } else {
        final note = SafeNote(
          title: titleDb,
          description: bodyDb,
          createdTime: DateTime.now(),
          noteType: noteType,
          contentFormat: contentFormat,
        );
        _working = await NotesDatabase.instance.encryptAndStore(note);
      }
      _lastTitleDb = titleDb;
      _lastBodyDb = bodyDb;
      NoteEditorState.applyPersistedSnapshot(
        note: _working!,
        titleUi: titleUi,
        descriptionSerialized: body,
        persistedContentFormat: contentFormat,
        persistedNoteType: noteType,
      );
      onPersisted?.call(_working!);
    } catch (e, st) {
      onError?.call(e, st);
    }
  }

  void dispose() {
    _debounce?.cancel();
  }
}
