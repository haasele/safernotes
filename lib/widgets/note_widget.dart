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

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:easy_localization/easy_localization.dart';
import 'package:local_session_timeout/local_session_timeout.dart';

// Project imports:
import 'package:safenotes/data/preference_and_config.dart';
import 'package:safenotes/utils/text_direction_util.dart';
import 'package:safenotes/widgets/markdown_editor.dart';

class NoteFormWidget extends StatelessWidget {
  final StreamController<SessionState> sessionStateStream;

  final String? title;
  final String? description;
  final String contentFormat;
  final ValueChanged<String> onChangedTitle;
  final ValueChanged<String> onChangedDescription;

  final GlobalKey<MarkdownNoteEditorState>? editorKey;

  const NoteFormWidget({
    Key? key,
    this.title = '',
    this.description = '',
    this.contentFormat = 'plain',
    required this.onChangedTitle,
    required this.onChangedDescription,
    required this.sessionStateStream,
    this.editorKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double allSidePadding = 16.0;

    return Padding(
      padding: const EdgeInsets.all(allSidePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTitle(),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Expanded(
            child: MarkdownNoteEditor(
              key: editorKey,
              initialContent: description ?? '',
              contentFormat: contentFormat,
              readOnly: false,
              onChanged: onChangedDescription,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    const double fontSize = 24.0;
    const int maxLinesToShowAtTimeTitle = 2;
    final String titleHint = 'Title'.tr();
    final bool enableIMEPLFlag = !PreferencesStorage.keyboardIncognito;

    return TextFormField(
      autofocus: true,
      enableIMEPersonalizedLearning: enableIMEPLFlag,
      maxLines: maxLinesToShowAtTimeTitle,
      textDirection: getTextDirecton(title!),
      initialValue: title,
      enableInteractiveSelection: true,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: titleHint,
      ),
      onChanged: onChangedTitle,
    );
  }
}
