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
import 'package:safenotes/utils/note_type_utils.dart';
import 'package:safenotes/utils/notes_color.dart';
import 'package:safenotes/utils/string_utils.dart';
import 'package:safenotes/utils/text_direction_util.dart';

class NoteTileWidgetCompact extends StatelessWidget {
  final SafeNote note;
  final int index;
  final bool isSelected;
  final bool showDragHandle;

  const NoteTileWidgetCompact({
    Key? key,
    required this.note,
    required this.index,
    this.isSelected = false,
    this.showDragHandle = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = NotesColor.getNoteColor(
      notIndex: index,
      context: context,
      fixedColorIndex: note.colorIndex,
    );
    final fontColor = getFontColorForBackground(color);
    final previewText = note.title == ' ' ? note.description : note.title;
    final cs = Theme.of(context).colorScheme;

    return Card(
      color: color,
      shadowColor: cs.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: cs.primary, width: 2)
            : BorderSide.none,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                if (note.noteType != 'text')
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      noteTypeIcon(note.noteType),
                      size: 16,
                      color: fontColor.withAlpha(180),
                    ),
                  ),
                Expanded(
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
              ],
            ),
          ),
          if (isSelected)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
                child: Icon(Icons.check, size: 16, color: cs.onPrimary),
              ),
            ),
          if (showDragHandle)
            Positioned(
              top: 0,
              bottom: 0,
              right: 8,
              child: Icon(
                Icons.drag_handle,
                size: 20,
                color: fontColor.withAlpha(120),
              ),
            ),
        ],
      ),
    );
  }
}
