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
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';

// Project imports:
import 'package:safenotes/data/preference_and_config.dart';
import 'package:safenotes/utils/notes_color.dart';

class ColorPallet extends StatefulWidget {
  const ColorPallet({Key? key}) : super(key: key);

  @override
  State<ColorPallet> createState() => ColorPalletState();
}

class ColorPalletState extends State<ColorPallet> {
  var _selectedIndex = PreferencesStorage.colorfulNotesColorIndex
      .clamp(0, allNoteColorPresets.length - 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notes Color'.tr())),
      body: _settings(),
    );
  }

  Widget _settings() {
    return SettingsList(
      sections: [
        SettingsSection(
          tiles: <SettingsTile>[
            SettingsTile.switchTile(
              initialValue: PreferencesStorage.isColorful,
              title: Text('Colorful Notes'.tr()),
              onToggle: (value) {
                final provider = Provider.of<NotesColor>(
                  context,
                  listen: false,
                );
                provider.toggleColor();
                setState(() {});
              },
              description: Text('Choose the note color theme from below'.tr()),
            ),
          ],
        ),
        CustomSettingsSection(
          child: Column(
            children: [_colourPreview(), _buildPresetList(context)],
          ),
        ),
      ],
    );
  }

  Widget _colourPreview() {
    final cs = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final preset = allNoteColorPresets[_selectedIndex];

    Color? dynamicSeed;
    if (preset.isDynamic) {
      dynamicSeed = cs.primary;
    }
    final colors = preset.generatePalette(brightness, dynamicSeed: dynamicSeed);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Card(
        color: cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _colorBoxes(colors),
          ),
        ),
      ),
    );
  }

  List<Widget> _colorBoxes(List<Color> colors) {
    final double heightRatio = MediaQuery.of(context).size.height / 100;
    final double boxHeight = heightRatio * 5;
    const double radius = 20;

    return List.generate(colors.length, (i) {
      BorderRadius? br;
      if (i == 0) {
        br = const BorderRadius.horizontal(left: Radius.circular(radius));
      } else if (i == colors.length - 1) {
        br = const BorderRadius.horizontal(right: Radius.circular(radius));
      }
      return Expanded(
        child: Container(
          decoration: BoxDecoration(color: colors[i], borderRadius: br),
          height: boxHeight,
        ),
      );
    });
  }

  Widget _buildPresetList(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: List.generate(allNoteColorPresets.length, (index) {
            final preset = allNoteColorPresets[index];
            final isSelected = _selectedIndex == index;
            return ListTile(
              leading: _presetIcon(preset),
              title: Text(preset.name.tr()),
              subtitle: preset.description != null
                  ? Text(preset.description!.tr())
                  : null,
              trailing: isSelected
                  ? Icon(Icons.check, color: cs.primary)
                  : null,
              onTap: () => setState(() {
                PreferencesStorage.setColorfulNotesColorIndex(index);
                _selectedIndex = index;
                Provider.of<NotesColor>(context, listen: false)
                    .setPresetIndex(index);
              }),
            );
          }),
        ),
      ),
    );
  }

  Widget _presetIcon(NoteColorPreset preset) {
    if (preset.isDynamic) {
      return Icon(
        Icons.auto_awesome,
        color: Theme.of(context).colorScheme.primary,
      );
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: preset.seedColor,
        shape: BoxShape.circle,
      ),
    );
  }
}
