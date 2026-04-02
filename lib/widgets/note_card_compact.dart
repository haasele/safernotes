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

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:auto_size_text/auto_size_text.dart';

// Project imports:
import 'package:safenotes/models/safenote.dart';
import 'package:safenotes/utils/notes_color.dart';
import 'package:safenotes/utils/string_utils.dart';
import 'package:safenotes/utils/text_direction_util.dart';

class NoteCardWidgetCompact extends StatelessWidget {
  final SafeNote note;
  final int index;

  const NoteCardWidgetCompact({
    Key? key,
    required this.note,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = NotesColor.getNoteColor(
      notIndex: index,
      fallback: Theme.of(context).colorScheme.surfaceContainerHigh,
    );
    final fontColor = getFontColorForBackground(color);
    final previewText = note.title == ' ' ? note.description : note.title;

    return Card(
      shadowColor: Theme.of(context).colorScheme.shadow,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: AutoSizeText(
          sanitize(previewText),
          textDirection: getTextDirecton(previewText),
          style: TextStyle(
            color: fontColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          minFontSize: 15,
          maxLines: 2,
          overflow: TextOverflow.clip,
        ),
      ),
    );
  }
}
