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

// Project imports:
import 'package:safenotes/data/preference_and_config.dart';
import 'package:safenotes/models/app_theme.dart';

class NoteColorPreset {
  final String name;
  final String? description;
  final Color seedColor;
  final bool isDynamic;

  const NoteColorPreset({
    required this.name,
    this.description,
    required this.seedColor,
    this.isDynamic = false,
  });

  List<Color> generatePalette(Brightness brightness, {Color? dynamicSeed}) {
    final seed = (isDynamic && dynamicSeed != null) ? dynamicSeed : seedColor;
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return [
      scheme.primaryContainer,
      scheme.secondaryContainer,
      scheme.tertiaryContainer,
      scheme.primaryFixed,
      scheme.secondaryFixed,
    ];
  }
}

const List<NoteColorPreset> allNoteColorPresets = [
  NoteColorPreset(
    name: 'Material You',
    description: 'Dynamic colors from your device',
    seedColor: AppThemes.seedColor,
    isDynamic: true,
  ),
  NoteColorPreset(
    name: 'Arctic',
    description: 'Cool blue tones',
    seedColor: Color(0xFF88C0D0),
  ),
  NoteColorPreset(
    name: 'Coral',
    description: 'Warm terracotta tones',
    seedColor: Color(0xFFD08770),
  ),
  NoteColorPreset(
    name: 'Forest',
    description: 'Natural green tones',
    seedColor: Color(0xFFA3BE8C),
  ),
  NoteColorPreset(
    name: 'Lavender',
    description: 'Soft purple tones',
    seedColor: Color(0xFFB48EAD),
  ),
  NoteColorPreset(
    name: 'Sapphire',
    description: 'Deep blue tones',
    seedColor: Color(0xFF2E5266),
  ),
  NoteColorPreset(
    name: 'Sunset',
    description: 'Amber and orange tones',
    seedColor: Color(0xFFF9A12E),
  ),
  NoteColorPreset(
    name: 'Rose',
    description: 'Vibrant pink tones',
    seedColor: Color(0xFFFF3EA5),
  ),
  NoteColorPreset(
    name: 'Monochrome',
    description: 'Neutral grey tones',
    seedColor: Color(0xFF808080),
  ),
];

class NotesColor extends ChangeNotifier {
  static Color getNoteColor({
    required int notIndex,
    required BuildContext context,
    int? fixedColorIndex,
  }) {
    final brightness = Theme.of(context).brightness;

    if (!PreferencesStorage.isColorful && fixedColorIndex == null) {
      return Theme.of(context).colorScheme.surfaceContainerHigh;
    }

    final presetIndex = PreferencesStorage.colorfulNotesColorIndex
        .clamp(0, allNoteColorPresets.length - 1);
    final preset = allNoteColorPresets[presetIndex];

    Color? dynamicSeed;
    if (preset.isDynamic) {
      dynamicSeed = Theme.of(context).colorScheme.primary;
    }

    final palette = preset.generatePalette(brightness, dynamicSeed: dynamicSeed);

    if (fixedColorIndex != null && fixedColorIndex >= 0) {
      return palette[fixedColorIndex % palette.length];
    }

    return palette[notIndex % palette.length];
  }

  /// Returns the full palette for the current preset (used in color picker UI).
  static List<Color> getCurrentPalette(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final presetIndex = PreferencesStorage.colorfulNotesColorIndex
        .clamp(0, allNoteColorPresets.length - 1);
    final preset = allNoteColorPresets[presetIndex];

    Color? dynamicSeed;
    if (preset.isDynamic) {
      dynamicSeed = Theme.of(context).colorScheme.primary;
    }

    return preset.generatePalette(brightness, dynamicSeed: dynamicSeed);
  }

  void toggleColor() {
    PreferencesStorage.setIsColorful(!PreferencesStorage.isColorful);
    notifyListeners();
  }

  void setPresetIndex(int index) {
    PreferencesStorage.setColorfulNotesColorIndex(index);
    notifyListeners();
  }
}

Color getFontColorForBackground(Color background) {
  return (background.computeLuminance() > 0.179) ? Colors.black : Colors.white;
}
