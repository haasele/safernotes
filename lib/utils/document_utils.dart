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
import 'package:appflowy_editor/appflowy_editor.dart';

bool isDocumentJson(String content) {
  if (content.isEmpty || content.trim().isEmpty) return false;
  try {
    final json = jsonDecode(content);
    return json is Map && json.containsKey('document');
  } catch (_) {
    return false;
  }
}

Document plainTextToDocument(String text) {
  if (text.trim().isEmpty) {
    return Document.blank();
  }
  try {
    final doc = markdownToDocument(text);
    if (doc.root.children.isEmpty) {
      return Document.blank();
    }
    return doc;
  } catch (_) {
    return Document.blank();
  }
}

String documentToJson(Document document) {
  return jsonEncode(document.toJson());
}

Document documentFromJson(String jsonString) {
  final json = Map<String, Object>.from(jsonDecode(jsonString));
  return Document.fromJson(json);
}

String documentToPlainText(Document document) {
  final buffer = StringBuffer();
  for (final node in document.root.children) {
    final text = node.delta?.toPlainText() ?? '';
    buffer.writeln(text);
  }
  return buffer.toString().trimRight();
}

Document resolveDescription(String description, String contentFormat) {
  if (contentFormat == 'document' && isDocumentJson(description)) {
    try {
      final doc = documentFromJson(description);
      if (doc.root.children.isEmpty) {
        return Document.blank();
      }
      return doc;
    } catch (_) {
      return plainTextToDocument(description);
    }
  }
  return plainTextToDocument(description);
}

String serializeDocument(Document document) {
  return documentToJson(document);
}

String extractPreviewText(String description, String contentFormat) {
  if (contentFormat == 'document' && isDocumentJson(description)) {
    try {
      final doc = documentFromJson(description);
      return documentToPlainText(doc);
    } catch (_) {
      return description;
    }
  }
  return description;
}
