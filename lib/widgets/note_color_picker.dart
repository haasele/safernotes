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
import 'package:easy_localization/easy_localization.dart';

// Project imports:
import 'package:safenotes/utils/notes_color.dart';

/// Returns the selected global color index, or -1 for "default (follow preset)", or null if dismissed.
Future<int?> showNoteColorPicker(BuildContext context) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) =>
          _NoteColorPickerSheet(scrollController: scrollController),
    ),
  );
}

class _NoteColorPickerSheet extends StatelessWidget {
  final ScrollController scrollController;

  const _NoteColorPickerSheet({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final surface = cs.surface;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Color'.tr(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildColorCircle(
                  context: context,
                  color: cs.surfaceContainerHigh,
                  index: -1,
                  label: 'Default'.tr(),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              itemCount: allNoteColorPresets.length,
              itemBuilder: (context, presetIdx) {
                final preset = allNoteColorPresets[presetIdx];
                Color? seed;
                if (preset.isDynamic) seed = cs.primary;
                final palette = preset.generatePalette(
                  brightness,
                  dynamicSeed: seed,
                  surface: surface,
                );
                final globalOffset = presetIdx * NotesColor.colorsPerPreset;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preset.name.tr(),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: List.generate(palette.length, (i) {
                          return _buildColorCircle(
                            context: context,
                            color: palette[i],
                            index: globalOffset + i,
                          );
                        }),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorCircle({
    required BuildContext context,
    required Color color,
    required int index,
    String? label,
  }) {
    final fontColor = getFontColorForBackground(color);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => Navigator.of(context).pop(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              ),
            ),
            child: index == -1
                ? Icon(Icons.format_color_reset, color: fontColor, size: 20)
                : null,
          ),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ],
      ),
    );
  }
}
