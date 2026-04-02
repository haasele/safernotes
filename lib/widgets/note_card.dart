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
import 'package:easy_localization/easy_localization.dart';

// Project imports:
import 'package:safenotes/models/safenote.dart';
import 'package:safenotes/utils/note_type_utils.dart';
import 'package:safenotes/utils/notes_color.dart';
import 'package:safenotes/utils/string_utils.dart';
import 'package:safenotes/utils/text_direction_util.dart';
import 'package:safenotes/utils/time_utils.dart';

class NoteCardWidget extends StatelessWidget {
  final SafeNote note;
  final int index;
  final bool isSelected;
  final bool showDragHandle;

  const NoteCardWidget({
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

    DateTime now = DateTime.now();
    DateTime todayDate = DateTime(now.year, now.month, now.day);
    DateTime noteDate = DateTime(
      note.createdTime.year,
      note.createdTime.month,
      note.createdTime.day,
    );
    String time = (todayDate == noteDate)
        ? humanTime(
            time: note.createdTime,
            localeString: context.locale.toString(),
          )
        : DateFormat.yMMMd().format(note.createdTime);

    final cs = Theme.of(context).colorScheme;

    return Card(
      shadowColor: cs.shadow,
      color: color,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AutoSizeText(
                  sanitize(note.title),
                  textDirection: getTextDirecton(note.title),
                  style: TextStyle(
                    color: fontColor,
                    fontSize: 20,
                    height: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                  minFontSize: 20,
                  maxLines: 2,
                  overflow: TextOverflow.clip,
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  textDirection: getTextDirecton(time),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fontColor,
                  ),
                ),
                if (note.noteType != 'text') ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        noteTypeIcon(note.noteType),
                        size: 14,
                        color: fontColor.withAlpha(180),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        noteTypePreviewText(
                          note.description,
                          note.noteType,
                          note.contentFormat,
                        ),
                        style: TextStyle(
                          color: fontColor.withAlpha(180),
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                AutoSizeText(
                  note.noteType == 'text'
                      ? sanitize(
                          noteTypePreviewText(
                            note.description,
                            note.noteType,
                            note.contentFormat,
                          ),
                        )
                      : '',
                  textDirection: getTextDirecton(note.description),
                  style:
                      TextStyle(color: fontColor, fontSize: 16, height: 1.2),
                  minFontSize: 16,
                  maxLines: getMaxLine(index),
                  overflow: TextOverflow.clip,
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
              bottom: 4,
              right: 4,
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

  int getMaxLine(int index) {
    switch (index % 4) {
      case 0:
        return 2;
      case 1:
        return 3;
      case 2:
        return 4;
      case 3:
        return 3;
      default:
        return 3;
    }
  }
}
