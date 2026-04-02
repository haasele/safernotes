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
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:appflowy_editor/appflowy_editor.dart';

// Project imports:
import 'package:safenotes/utils/document_utils.dart';

class MarkdownNoteEditor extends StatefulWidget {
  final String initialContent;
  final String contentFormat;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final Color? backgroundColor;

  const MarkdownNoteEditor({
    super.key,
    required this.initialContent,
    this.contentFormat = 'plain',
    this.readOnly = false,
    this.onChanged,
    this.backgroundColor,
  });

  @override
  State<MarkdownNoteEditor> createState() => MarkdownNoteEditorState();
}

class MarkdownNoteEditorState extends State<MarkdownNoteEditor> {
  late EditorState _editorState;
  late EditorScrollController _scrollController;

  EditorState get editorState => _editorState;

  @override
  void initState() {
    super.initState();
    _initEditor();
  }

  void _initEditor() {
    final document = resolveDescription(
      widget.initialContent,
      widget.contentFormat,
    );
    _editorState = EditorState(document: document);
    _scrollController = EditorScrollController(
      editorState: _editorState,
    );

    if (!widget.readOnly && widget.onChanged != null) {
      _editorState.transactionStream.listen((_) {
        final serialized = serializeDocument(_editorState.document);
        widget.onChanged?.call(serialized);
      });
    }
  }

  @override
  void dispose() {
    _editorState.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String getSerializedContent() {
    return serializeDocument(_editorState.document);
  }

  bool get _isMobile =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final editorStyle = _buildEditorStyle(context, isDark);

    if (widget.readOnly) {
      _editorState.editable = false;
    }

    return AppFlowyEditor(
      editorState: _editorState,
      editorScrollController: _scrollController,
      editorStyle: editorStyle,
      blockComponentBuilders: standardBlockComponentBuilderMap,
      characterShortcutEvents: widget.readOnly
          ? []
          : standardCharacterShortcutEvents,
      commandShortcutEvents: widget.readOnly
          ? []
          : standardCommandShortcutEvents,
      footer: widget.readOnly ? null : _buildMobileToolbar(context),
    );
  }

  EditorStyle _buildEditorStyle(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (_isMobile) {
      return EditorStyle.mobile(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        cursorColor: primaryColor,
        dragHandleColor: primaryColor,
        selectionColor: primaryColor.withAlpha(80),
        textStyleConfiguration: TextStyleConfiguration(
          text: TextStyle(
            fontSize: 17.0,
            color: textColor,
            height: 1.5,
          ),
          bold: const TextStyle(fontWeight: FontWeight.w700),
          italic: const TextStyle(fontStyle: FontStyle.italic),
          underline: const TextStyle(decoration: TextDecoration.underline),
          strikethrough: const TextStyle(
            decoration: TextDecoration.lineThrough,
          ),
          href: TextStyle(
            color: primaryColor,
            decoration: TextDecoration.underline,
          ),
          code: TextStyle(
            fontSize: 14.0,
            fontFamily: 'monospace',
            color: isDark ? Colors.orange.shade200 : Colors.deepOrange,
            backgroundColor: isDark
                ? Colors.white.withAlpha(20)
                : Colors.grey.withAlpha(30),
          ),
        ),
      );
    }

    return EditorStyle.desktop(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      cursorColor: primaryColor,
      selectionColor: primaryColor.withAlpha(80),
      textStyleConfiguration: TextStyleConfiguration(
        text: TextStyle(
          fontSize: 17.0,
          color: textColor,
          height: 1.5,
        ),
        bold: const TextStyle(fontWeight: FontWeight.w700),
        italic: const TextStyle(fontStyle: FontStyle.italic),
        underline: const TextStyle(decoration: TextDecoration.underline),
        strikethrough: const TextStyle(
          decoration: TextDecoration.lineThrough,
        ),
        href: TextStyle(
          color: primaryColor,
          decoration: TextDecoration.underline,
        ),
        code: TextStyle(
          fontSize: 14.0,
          fontFamily: 'monospace',
          color: isDark ? Colors.orange.shade200 : Colors.deepOrange,
          backgroundColor: isDark
              ? Colors.white.withAlpha(20)
              : Colors.grey.withAlpha(30),
        ),
      ),
    );
  }

  Widget? _buildMobileToolbar(BuildContext context) {
    if (!_isMobile) return null;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return MobileToolbar(
      editorState: _editorState,
      backgroundColor: isDark ? cs.surface : Colors.white,
      foregroundColor: isDark ? Colors.white70 : const Color(0xff676666),
      itemHighlightColor: cs.primary,
      primaryColor: cs.primary,
      onPrimaryColor: cs.onPrimary,
      toolbarItems: [
        textDecorationMobileToolbarItem,
        headingMobileToolbarItem,
        todoListMobileToolbarItem,
        listMobileToolbarItem,
        linkMobileToolbarItem,
        quoteMobileToolbarItem,
        codeMobileToolbarItem,
        dividerMobileToolbarItem,
      ],
    );
  }
}
