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

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:appflowy_editor/appflowy_editor.dart';

// Project imports:
import 'package:safenotes/utils/document_utils.dart';
import 'package:safenotes/widgets/appflowy_floating_format_bar.dart';
import 'package:safenotes/widgets/safenotes_link_toolbar.dart';

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
  StreamSubscription<dynamic>? _transactionSub;

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
    _editorState.editable = !widget.readOnly;
    _scrollController = EditorScrollController(
      editorState: _editorState,
    );

    if (!widget.readOnly && widget.onChanged != null) {
      _transactionSub = _editorState.transactionStream.listen((_) {
        final serialized = serializeDocument(_editorState.document);
        widget.onChanged?.call(serialized);
      });
    }
  }

  @override
  void dispose() {
    _transactionSub?.cancel();
    _editorState.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MarkdownNoteEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.readOnly != widget.readOnly) {
      _editorState.editable = !widget.readOnly;
    }
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

    final editor = RepaintBoundary(
      child: AppFlowyEditor(
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
        footer: null,
        autoScrollEdgeOffset: _isMobile ? 300.0 : 220.0,
      ),
    );

    if (!_isMobile || widget.readOnly) {
      return editor;
    }

    final cs = Theme.of(context).colorScheme;
    final toolbarItems = <MobileToolbarItem>[
      textDecorationMobileToolbarItemV2,
      buildTextAndBackgroundColorMobileToolbarItem(),
      blocksMobileToolbarItem,
      safenotesLinkMobileToolbarItem,
      dividerMobileToolbarItem,
    ];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: editor),
        AppflowyFloatingFormatBar(
          editorState: _editorState,
          toolbarItems: toolbarItems,
          isDark: isDark,
          primaryColor: cs.primary,
          onPrimaryColor: cs.onPrimary,
        ),
      ],
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
}
