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
import 'dart:convert';

// Package imports:
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// Project imports:
import 'package:safenotes/data/preference_and_config.dart';
import 'package:safenotes/models/attachment.dart';
import 'package:safenotes/models/safenote.dart';

class NotesDatabase {
  static final NotesDatabase instance = NotesDatabase._init();

  static Database? _database;

  NotesDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('._my_system_note');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';

    await db.execute('''
  CREATE TABLE $tableNotes ( 
  ${NoteFields.id} $idType, 
  ${NoteFields.title} $textType,
  ${NoteFields.description} $textType,
  ${NoteFields.time} $textType,
  ${NoteFields.colorIndex} INTEGER,
  ${NoteFields.modifiedTime} TEXT,
  ${NoteFields.sortOrder} INTEGER,
  ${NoteFields.noteType} TEXT DEFAULT 'text',
  ${NoteFields.contentFormat} TEXT DEFAULT 'plain'
  )
  ''');

    await db.execute('''
  CREATE TABLE $tableAttachments (
  ${AttachmentFields.id} $idType,
  ${AttachmentFields.noteId} INTEGER NOT NULL,
  ${AttachmentFields.fileName} $textType,
  ${AttachmentFields.storagePath} $textType,
  ${AttachmentFields.mimeType} TEXT,
  ${AttachmentFields.fileSize} INTEGER,
  ${AttachmentFields.createdTime} $textType,
  FOREIGN KEY (${AttachmentFields.noteId}) REFERENCES $tableNotes(${NoteFields.id}) ON DELETE CASCADE
  )
  ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE $tableNotes ADD COLUMN ${NoteFields.colorIndex} INTEGER',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE $tableNotes ADD COLUMN ${NoteFields.modifiedTime} TEXT',
      );
      await db.execute(
        'ALTER TABLE $tableNotes ADD COLUMN ${NoteFields.sortOrder} INTEGER',
      );
      await db.execute(
        'UPDATE $tableNotes SET ${NoteFields.modifiedTime} = ${NoteFields.time} WHERE ${NoteFields.modifiedTime} IS NULL',
      );
    }
    if (oldVersion < 4) {
      await db.execute(
        "ALTER TABLE $tableNotes ADD COLUMN ${NoteFields.noteType} TEXT DEFAULT 'text'",
      );
      await db.execute(
        "ALTER TABLE $tableNotes ADD COLUMN ${NoteFields.contentFormat} TEXT DEFAULT 'plain'",
      );
      await db.execute('''
  CREATE TABLE IF NOT EXISTS $tableAttachments (
  ${AttachmentFields.id} INTEGER PRIMARY KEY AUTOINCREMENT,
  ${AttachmentFields.noteId} INTEGER NOT NULL,
  ${AttachmentFields.fileName} TEXT NOT NULL,
  ${AttachmentFields.storagePath} TEXT NOT NULL,
  ${AttachmentFields.mimeType} TEXT,
  ${AttachmentFields.fileSize} INTEGER,
  ${AttachmentFields.createdTime} TEXT NOT NULL,
  FOREIGN KEY (${AttachmentFields.noteId}) REFERENCES $tableNotes(${NoteFields.id}) ON DELETE CASCADE
  )
  ''');
    }
  }

  Future<SafeNote> encryptAndStore(SafeNote note) async {
    final db = await instance.database;
    final now = DateTime.now();
    final noteWithMod = note.copy(modifiedTime: now);
    final id = await db.insert(tableNotes, noteWithMod.toJsonAndEncrypted());

    await PreferencesStorage.setIsBackupNeeded(true);

    return noteWithMod.copy(id: id);
  }

  Future<SafeNote> decryptReadNote(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      tableNotes,
      columns: NoteFields.values,
      where: '${NoteFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return SafeNote.fromJsonAndDecrypt(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<SafeNote>> decryptReadAllNotes() async {
    final db = await instance.database;
    const orderBy = '${NoteFields.time} ASC';
    final result = await db.query(tableNotes, orderBy: orderBy);

    return result.map((json) => SafeNote.fromJsonAndDecrypt(json)).toList();
  }

  Future<String> exportAllEncrypted() async {
    final db = await instance.database;
    const orderBy = '${NoteFields.time} ASC';
    final result = await db.query(
      tableNotes,
      columns: ['title', 'description', 'time', 'colorIndex', 'modifiedTime', 'sortOrder'],
      orderBy: orderBy,
    );

    return jsonEncode(result).toString();
  }

  Future<int> encryptAndUpdate(SafeNote note) async {
    final db = await instance.database;

    await PreferencesStorage.setIsBackupNeeded(true);

    final noteWithMod = note.copy(modifiedTime: DateTime.now());
    return db.update(
      tableNotes,
      noteWithMod.toJsonAndEncrypted(),
      where: '${NoteFields.id} = ?',
      whereArgs: [noteWithMod.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;

    await PreferencesStorage.setIsBackupNeeded(true);

    return await db.delete(
      tableNotes,
      where: '${NoteFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteMultiple(List<int> ids) async {
    if (ids.isEmpty) return 0;
    final db = await instance.database;

    await PreferencesStorage.setIsBackupNeeded(true);

    final placeholders = ids.map((_) => '?').join(',');
    return await db.delete(
      tableNotes,
      where: '${NoteFields.id} IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Future<void> updateColorIndex(List<int> ids, int? colorIndex) async {
    if (ids.isEmpty) return;
    final db = await instance.database;

    await PreferencesStorage.setIsBackupNeeded(true);

    final placeholders = ids.map((_) => '?').join(',');
    await db.update(
      tableNotes,
      {NoteFields.colorIndex: colorIndex},
      where: '${NoteFields.id} IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Future<void> updateSortOrder(Map<int, int> idToOrder) async {
    if (idToOrder.isEmpty) return;
    final db = await instance.database;
    final batch = db.batch();
    for (final entry in idToOrder.entries) {
      batch.update(
        tableNotes,
        {NoteFields.sortOrder: entry.value},
        where: '${NoteFields.id} = ?',
        whereArgs: [entry.key],
      );
    }
    await batch.commit(noResult: true);
  }

  // Attachment CRUD

  Future<NoteAttachment> insertAttachment(NoteAttachment attachment) async {
    final db = await instance.database;
    final id = await db.insert(tableAttachments, attachment.toMap());
    return attachment.copy(id: id);
  }

  Future<List<NoteAttachment>> getAttachmentsForNote(int noteId) async {
    final db = await instance.database;
    final result = await db.query(
      tableAttachments,
      where: '${AttachmentFields.noteId} = ?',
      whereArgs: [noteId],
    );
    return result.map((map) => NoteAttachment.fromMap(map)).toList();
  }

  Future<int> deleteAttachment(int attachmentId) async {
    final db = await instance.database;
    return await db.delete(
      tableAttachments,
      where: '${AttachmentFields.id} = ?',
      whereArgs: [attachmentId],
    );
  }

  Future<int> deleteAttachmentsForNote(int noteId) async {
    final db = await instance.database;
    return await db.delete(
      tableAttachments,
      where: '${AttachmentFields.noteId} = ?',
      whereArgs: [noteId],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
