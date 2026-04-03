/*
* Copyright (C) Keshav Priyadarshi and others - All Rights Reserved.
*
* SPDX-License-Identifier: GPL-3.0-or-later
*/

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Link action with a keyboard-safe bottom sheet (no [keyboardService.disable]).
final safenotesLinkMobileToolbarItem = MobileToolbarItem.action(
  itemIconBuilder: (context, editorState, _) {
    final iconColor = MobileToolbarTheme.maybeOf(context)?.iconColor ??
        Theme.of(context).colorScheme.onSurface;
    return AFMobileIcon(
      afMobileIcons: AFMobileIcons.link,
      color: iconColor,
    );
  },
  actionHandler: (context, editorState) {
    final selection = editorState.selection;
    if (selection == null) return;
    final captured = selection;
    final linkText = editorState.getDeltaAttributeValueInSelection(
      AppFlowyRichTextKeys.href,
      captured,
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return AnimatedPadding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: _SafenotesLinkSheet(
            editorState: editorState,
            capturedSelection: captured,
            initialUrl: linkText,
          ),
        );
      },
    );
  },
);

class _SafenotesLinkSheet extends StatefulWidget {
  const _SafenotesLinkSheet({
    required this.editorState,
    required this.capturedSelection,
    this.initialUrl,
  });

  final EditorState editorState;
  final Selection capturedSelection;
  final String? initialUrl;

  @override
  State<_SafenotesLinkSheet> createState() => _SafenotesLinkSheetState();
}

class _SafenotesLinkSheetState extends State<_SafenotesLinkSheet> {
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl ?? '');
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _applyAndClose() async {
    final url = _urlController.text.trim();
    final nav = Navigator.of(context);
    final es = widget.editorState;
    es.selection = widget.capturedSelection;
    if (url.isNotEmpty) {
      await es.formatDelta(widget.capturedSelection, {
        AppFlowyRichTextKeys.href: url,
      });
    }
    if (nav.canPop()) nav.pop();
    final sel = es.selection ?? widget.capturedSelection;
    es.service.keyboardService?.enableKeyBoard(sel);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _urlController,
              autofocus: true,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _applyAndClose(),
              decoration: InputDecoration(
                labelText: 'URL',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _urlController.clear,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.editorState.service.keyboardService
                          ?.enableKeyBoard(widget.capturedSelection);
                    },
                    child: Text('Cancel'.tr()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _applyAndClose,
                    child: Text('Done'.tr()),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.paddingOf(context).bottom + 8),
          ],
        ),
      ),
    );
  }
}
