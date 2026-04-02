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

// Project imports:
import 'package:safenotes/data/preference_and_config.dart';
import 'package:safenotes/encryption/aes_encryption.dart';

const String tableNotes = 'safe_notes';

class NoteFields {
  static final List<String> values = [id, title, description, time, colorIndex];

  static const String id = '_id';
  static const String title = 'title';
  static const String description = 'description';
  static const String time = 'time';
  static const String colorIndex = 'colorIndex';
}

class SafeNote {
  final int? id;
  final String title;
  final String description;
  final DateTime createdTime;
  final int? colorIndex;

  const SafeNote({
    this.id,
    required this.title,
    required this.description,
    required this.createdTime,
    this.colorIndex,
  });

  SafeNote copy({
    int? id,
    String? title,
    String? description,
    DateTime? createdTime,
    int? colorIndex,
    bool clearColor = false,
  }) => SafeNote(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    createdTime: createdTime ?? this.createdTime,
    colorIndex: clearColor ? null : (colorIndex ?? this.colorIndex),
  );

  static SafeNote fromJsonAndDecrypt(Map<String, dynamic> json) {
    return SafeNote(
      id: json[NoteFields.id] as int?,
      title: decryptAES(
        json[NoteFields.title] as String,
        PhraseHandler.getPass,
      ),
      description: decryptAES(
        json[NoteFields.description] as String,
        PhraseHandler.getPass,
      ),
      createdTime: DateTime.parse(json[NoteFields.time] as String),
      colorIndex: json[NoteFields.colorIndex] as int?,
    );
  }

  Map<String, dynamic> toJsonAndEncrypted() {
    String passphrase = PhraseHandler.getPass;
    return {
      NoteFields.id: id,
      NoteFields.title: encryptAES(title, passphrase),
      NoteFields.description: encryptAES(description, passphrase),
      NoteFields.time: createdTime.toIso8601String(),
      NoteFields.colorIndex: colorIndex,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      NoteFields.title: encryptAES(title, PhraseHandler.getPass),
      NoteFields.description: encryptAES(description, PhraseHandler.getPass),
      NoteFields.time: createdTime.toIso8601String(),
      NoteFields.colorIndex: colorIndex,
    };
  }

  static SafeNote fromJson(Map<String, dynamic> json) {
    /*
    Attention: Starting v2.0 unencrypted export is removed, 
    however user are allowed to import their unencrypted backup until v3.0 
    */
    final bool isImportEncrypted =
        ImportEncryptionControl.getIsImportEncrypted();
    return SafeNote(
      title: isImportEncrypted
          ? decryptAES(
              json[NoteFields.title] as String,
              ImportPassPhraseHandler.getImportPassPhrase(),
            )
          : json[NoteFields.title] as String,
      description: isImportEncrypted
          ? decryptAES(
              json[NoteFields.description] as String,
              ImportPassPhraseHandler.getImportPassPhrase(),
            )
          : json[NoteFields.description] as String,
      createdTime: DateTime.parse(json[NoteFields.time] as String),
      colorIndex: json[NoteFields.colorIndex] as int?,
    );
  }
}
