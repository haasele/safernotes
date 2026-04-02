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
import 'dart:io';
import 'dart:typed_data';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_session_timeout/local_session_timeout.dart';

// Project imports:
import 'package:safenotes/data/attachment_handler.dart';
import 'package:safenotes/data/database_handler.dart';
import 'package:safenotes/models/safenote.dart';

class ImageNoteEditor extends StatefulWidget {
  final StreamController<SessionState> sessionStateStream;
  final SafeNote? note;

  const ImageNoteEditor({
    super.key,
    required this.sessionStateStream,
    this.note,
  });

  @override
  State<ImageNoteEditor> createState() => _ImageNoteEditorState();
}

class _ImageNoteEditorState extends State<ImageNoteEditor> {
  final _titleController = TextEditingController();
  final _captionController = TextEditingController();
  final _picker = ImagePicker();
  File? _imageFile;
  Uint8List? _existingImageBytes;
  bool _loadingExisting = false;

  bool get _hasImage => _imageFile != null || _existingImageBytes != null;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      final desc = widget.note!.description;
      if (desc != 'image_note' && desc.isNotEmpty) {
        _captionController.text = desc;
      }
      _loadExistingImage();
    }
  }

  Future<void> _loadExistingImage() async {
    if (widget.note?.id == null) return;
    setState(() => _loadingExisting = true);
    try {
      final attachments = await NotesDatabase.instance
          .getAttachmentsForNote(widget.note!.id!);
      if (attachments.isNotEmpty) {
        final bytes = await AttachmentHandler.instance
            .decryptAndReadFile(attachments.first.storagePath);
        if (mounted) {
          setState(() {
            _existingImageBytes = bytes;
            _loadingExisting = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingExisting = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingExisting = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _existingImageBytes = null;
      });
    }
  }

  Future<void> _save() async {
    if (!_hasImage) return;

    final navigator = Navigator.of(context);
    final title = _titleController.text.isEmpty
        ? 'Image Note'.tr()
        : _titleController.text;
    final caption = _captionController.text;

    final isEditing = widget.note != null;

    if (isEditing) {
      final updated = widget.note!.copy(
        title: title,
        description: caption.isEmpty ? 'image_note' : caption,
        createdTime: DateTime.now(),
      );
      await NotesDatabase.instance.encryptAndUpdate(updated);

      if (_imageFile != null) {
        await AttachmentHandler.instance.deleteAllForNote(widget.note!.id!);

        final ext = _imageFile!.path.split('.').last.toLowerCase();
        await AttachmentHandler.instance.encryptAndStoreFile(
          noteId: widget.note!.id!,
          sourceFile: _imageFile!,
          fileName: 'image.$ext',
          mimeType: 'image/$ext',
        );
      }
    } else {
      final note = SafeNote(
        title: title,
        description: caption.isEmpty ? 'image_note' : caption,
        createdTime: DateTime.now(),
        noteType: 'image',
        contentFormat: 'plain',
      );

      final saved = await NotesDatabase.instance.encryptAndStore(note);

      if (saved.id != null && _imageFile != null) {
        final ext = _imageFile!.path.split('.').last.toLowerCase();
        await AttachmentHandler.instance.encryptAndStoreFile(
          noteId: saved.id!,
          sourceFile: _imageFile!,
          fileName: 'image.$ext',
          mimeType: 'image/$ext',
        );
      }
    }

    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Image Note'.tr()),
        actions: [
          if (_hasImage)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primaryContainer,
                  foregroundColor: cs.onPrimaryContainer,
                ),
                onPressed: _save,
                child: Text('Save'.tr(),
                  style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Title'.tr(),
              ),
            ),
            const Divider(),
            Expanded(
              child: _loadingExisting
                  ? const Center(child: CircularProgressIndicator())
                  : _hasImage
                      ? _buildImagePreview()
                      : _buildPickerOptions(cs),
            ),
            if (_hasImage) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _captionController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: 'Add a caption...'.tr(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Change image',
                    onPressed: () => _showPickerSheet(cs),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(_imageFile!, fit: BoxFit.contain),
      );
    }
    if (_existingImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(_existingImageBytes!, fit: BoxFit.contain),
      );
    }
    return const SizedBox.shrink();
  }

  void _showPickerSheet(ColorScheme cs) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text('Camera'.tr()),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text('Gallery'.tr()),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOptions(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined, size: 80, color: cs.outline),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: Text('Camera'.tr()),
              ),
              const SizedBox(width: 16),
              FilledButton.tonalIcon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: Text('Gallery'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
