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
import 'dart:io';
import 'dart:typed_data';

// Package imports:
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

// Project imports:
import 'package:safenotes/data/database_handler.dart';
import 'package:safenotes/data/preference_and_config.dart';
import 'package:safenotes/encryption/aes_encryption.dart';
import 'package:safenotes/models/attachment.dart';

class AttachmentHandler {
  static final AttachmentHandler instance = AttachmentHandler._();
  AttachmentHandler._();

  Future<String> _attachmentDir(int noteId) async {
    final dir = await getApplicationDocumentsDirectory();
    final attachDir = Directory('${dir.path}/attachments/$noteId');
    if (!await attachDir.exists()) {
      await attachDir.create(recursive: true);
    }
    return attachDir.path;
  }

  Future<NoteAttachment> encryptAndStoreFile({
    required int noteId,
    required File sourceFile,
    required String fileName,
    String? mimeType,
  }) async {
    final dirPath = await _attachmentDir(noteId);
    final sourceBytes = await sourceFile.readAsBytes();

    final encryptedBase64 = encryptAES(
      base64Encode(sourceBytes),
      PhraseHandler.getPass,
    );
    final encFileName = '${const Uuid().v4()}.enc';
    final encPath = '$dirPath/$encFileName';
    await File(encPath).writeAsString(encryptedBase64);

    final attachment = NoteAttachment(
      noteId: noteId,
      fileName: fileName,
      storagePath: encPath,
      mimeType: mimeType,
      fileSize: sourceBytes.length,
      createdTime: DateTime.now(),
    );

    return await NotesDatabase.instance.insertAttachment(attachment);
  }

  Future<Uint8List> decryptAndReadFile(String storagePath) async {
    final encryptedBase64 = await File(storagePath).readAsString();
    final decryptedBase64 = decryptAES(
      encryptedBase64,
      PhraseHandler.getPass,
    );
    return base64Decode(decryptedBase64);
  }

  Future<void> deleteAttachmentFile(String storagePath) async {
    final file = File(storagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> deleteAllForNote(int noteId) async {
    final attachments =
        await NotesDatabase.instance.getAttachmentsForNote(noteId);
    for (final att in attachments) {
      await deleteAttachmentFile(att.storagePath);
    }
    await NotesDatabase.instance.deleteAttachmentsForNote(noteId);

    final dir = await getApplicationDocumentsDirectory();
    final attachDir = Directory('${dir.path}/attachments/$noteId');
    if (await attachDir.exists()) {
      await attachDir.delete(recursive: true);
    }
  }
}
