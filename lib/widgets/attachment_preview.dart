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
import 'dart:typed_data';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:audioplayers/audioplayers.dart';

// Project imports:
import 'package:safenotes/data/attachment_handler.dart';
import 'package:safenotes/models/attachment.dart';

class ImageAttachmentPreview extends StatefulWidget {
  final NoteAttachment attachment;

  const ImageAttachmentPreview({super.key, required this.attachment});

  @override
  State<ImageAttachmentPreview> createState() =>
      _ImageAttachmentPreviewState();
}

class _ImageAttachmentPreviewState extends State<ImageAttachmentPreview> {
  Uint8List? _bytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final bytes = await AttachmentHandler.instance
          .decryptAndReadFile(widget.attachment.storagePath);
      if (mounted) {
        setState(() {
          _bytes = bytes;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_bytes == null) {
      return Center(
        child: Icon(Icons.broken_image,
          size: 48,
          color: Theme.of(context).colorScheme.outline,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.memory(_bytes!, fit: BoxFit.contain),
    );
  }
}

class AudioAttachmentPreview extends StatefulWidget {
  final NoteAttachment attachment;

  const AudioAttachmentPreview({super.key, required this.attachment});

  @override
  State<AudioAttachmentPreview> createState() =>
      _AudioAttachmentPreviewState();
}

class _AudioAttachmentPreviewState extends State<AudioAttachmentPreview> {
  final _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _player.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
    } else {
      final bytes = await AttachmentHandler.instance
          .decryptAndReadFile(widget.attachment.storagePath);
      await _player.play(BytesSource(bytes));
      setState(() => _isPlaying = true);
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _togglePlay,
            icon: Icon(
              _isPlaying ? Icons.pause_circle : Icons.play_circle,
              size: 40,
              color: cs.primary,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.attachment.fileName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: _duration.inMilliseconds > 0
                      ? _position.inMilliseconds / _duration.inMilliseconds
                      : 0,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                  style: TextStyle(fontSize: 12, color: cs.outline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FileAttachmentPreview extends StatelessWidget {
  final NoteAttachment attachment;

  const FileAttachmentPreview({super.key, required this.attachment});

  IconData _iconForMime(String? mime) {
    if (mime == null) return Icons.insert_drive_file;
    if (mime.startsWith('text/')) return Icons.description;
    if (mime.startsWith('application/')) return Icons.folder_zip;
    return Icons.insert_drive_file;
  }

  String _formatSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _iconForMime(attachment.mimeType),
            size: 36,
            color: cs.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  attachment.fileName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatSize(attachment.fileSize),
                  style: TextStyle(fontSize: 12, color: cs.outline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildAttachmentPreview(NoteAttachment attachment) {
  if (attachment.isImage) {
    return ImageAttachmentPreview(attachment: attachment);
  }
  if (attachment.isAudio) {
    return AudioAttachmentPreview(attachment: attachment);
  }
  return FileAttachmentPreview(attachment: attachment);
}
