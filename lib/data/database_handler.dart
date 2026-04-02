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
      version: 2,
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
  ${NoteFields.colorIndex} INTEGER
  )
  ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE $tableNotes ADD COLUMN ${NoteFields.colorIndex} INTEGER',
      );
    }
  }

  Future<SafeNote> encryptAndStore(SafeNote note) async {
    final db = await instance.database;
    final id = await db.insert(tableNotes, note.toJsonAndEncrypted());

    await PreferencesStorage.setIsBackupNeeded(true);

    return note.copy(id: id);
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
      columns: ['title', 'description', 'time', 'colorIndex'],
      orderBy: orderBy,
    );

    return jsonEncode(result).toString();
  }

  Future<int> encryptAndUpdate(SafeNote note) async {
    final db = await instance.database;

    await PreferencesStorage.setIsBackupNeeded(true);

    return db.update(
      tableNotes,
      note.toJsonAndEncrypted(),
      where: '${NoteFields.id} = ?',
      whereArgs: [note.id],
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

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
