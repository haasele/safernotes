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

const String tableAttachments = 'note_attachments';

class AttachmentFields {
  static const String id = '_id';
  static const String noteId = 'noteId';
  static const String fileName = 'fileName';
  static const String storagePath = 'storagePath';
  static const String mimeType = 'mimeType';
  static const String fileSize = 'fileSize';
  static const String createdTime = 'createdTime';
}

class NoteAttachment {
  final int? id;
  final int noteId;
  final String fileName;
  final String storagePath;
  final String? mimeType;
  final int? fileSize;
  final DateTime createdTime;

  const NoteAttachment({
    this.id,
    required this.noteId,
    required this.fileName,
    required this.storagePath,
    this.mimeType,
    this.fileSize,
    required this.createdTime,
  });

  NoteAttachment copy({
    int? id,
    int? noteId,
    String? fileName,
    String? storagePath,
    String? mimeType,
    int? fileSize,
    DateTime? createdTime,
  }) => NoteAttachment(
    id: id ?? this.id,
    noteId: noteId ?? this.noteId,
    fileName: fileName ?? this.fileName,
    storagePath: storagePath ?? this.storagePath,
    mimeType: mimeType ?? this.mimeType,
    fileSize: fileSize ?? this.fileSize,
    createdTime: createdTime ?? this.createdTime,
  );

  Map<String, dynamic> toMap() => {
    AttachmentFields.noteId: noteId,
    AttachmentFields.fileName: fileName,
    AttachmentFields.storagePath: storagePath,
    AttachmentFields.mimeType: mimeType,
    AttachmentFields.fileSize: fileSize,
    AttachmentFields.createdTime: createdTime.toIso8601String(),
  };

  static NoteAttachment fromMap(Map<String, dynamic> map) => NoteAttachment(
    id: map[AttachmentFields.id] as int?,
    noteId: map[AttachmentFields.noteId] as int,
    fileName: map[AttachmentFields.fileName] as String,
    storagePath: map[AttachmentFields.storagePath] as String,
    mimeType: map[AttachmentFields.mimeType] as String?,
    fileSize: map[AttachmentFields.fileSize] as int?,
    createdTime: DateTime.parse(map[AttachmentFields.createdTime] as String),
  );

  bool get isImage =>
      mimeType != null && mimeType!.startsWith('image/');

  bool get isVideo =>
      mimeType != null && mimeType!.startsWith('video/');

  bool get isAudio =>
      mimeType != null && mimeType!.startsWith('audio/');
}
