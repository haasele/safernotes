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

class NoteTileWidget extends StatelessWidget {
  final SafeNote note;
  final int index;
  final bool isSelected;
  final bool showDragHandle;

  const NoteTileWidget({
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
    final cs = Theme.of(context).colorScheme;

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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
                const SizedBox.square(dimension: 5),
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
                  const SizedBox.square(dimension: 3),
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
                const SizedBox.square(dimension: 5),
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
                  maxLines: 2,
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
