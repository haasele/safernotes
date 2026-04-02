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

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:safenotes/utils/document_utils.dart';

IconData noteTypeIcon(String noteType) {
  switch (noteType) {
    case 'audio':
      return Icons.mic;
    case 'image':
      return Icons.image;
    case 'drawing':
      return Icons.brush;
    case 'checklist':
      return Icons.checklist;
    case 'text':
    default:
      return Icons.edit_note;
  }
}

String noteTypePreviewText(String description, String noteType, String contentFormat) {
  switch (noteType) {
    case 'audio':
      return 'Audio recording';
    case 'image':
      return description == 'image_note' ? 'Image' : description;
    case 'drawing':
      return 'Drawing';
    case 'checklist':
      return _checklistPreview(description);
    case 'text':
    default:
      return extractPreviewText(description, contentFormat);
  }
}

String _checklistPreview(String description) {
  try {
    final list = jsonDecode(description) as List;
    final total = list.length;
    final checked = list.where((e) => e['checked'] == true).length;
    return '$checked/$total done';
  } catch (_) {
    return description;
  }
}
