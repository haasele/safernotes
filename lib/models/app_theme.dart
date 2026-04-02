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

enum ThemeFlavor { system, materialYouLight, materialYouDark, pitchBlack }

class ThemeProvider extends ChangeNotifier {
  ThemeFlavor _flavor = ThemeFlavor.values[PreferencesStorage.themeFlavor];

  ThemeFlavor get flavor => _flavor;

  ThemeMode get themeMode {
    switch (_flavor) {
      case ThemeFlavor.system:
        return ThemeMode.system;
      case ThemeFlavor.materialYouLight:
        return ThemeMode.light;
      case ThemeFlavor.materialYouDark:
      case ThemeFlavor.pitchBlack:
        return ThemeMode.dark;
    }
  }

  ThemeData get lightTheme => AppThemes.materialYouLight;

  ThemeData get darkTheme {
    if (_flavor == ThemeFlavor.pitchBlack) return AppThemes.pitchBlack;
    return AppThemes.materialYouDark;
  }

  void setFlavor(ThemeFlavor flavor) {
    _flavor = flavor;
    PreferencesStorage.setThemeFlavor(flavor.index);
    notifyListeners();
  }
}

class AppThemes {
  static const Color _seedColor = Color(0xFF88C0D0);
  static const String _fontFamily = 'NotoSerif';

  static final ThemeData materialYouLight = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    ),
    fontFamily: _fontFamily,
  );

  static final ThemeData materialYouDark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
    fontFamily: _fontFamily,
  );

  static final ThemeData pitchBlack = () {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: baseScheme.copyWith(
        surface: Colors.black,
        onSurface: Colors.white,
        surfaceContainerLowest: Colors.black,
        surfaceContainerLow: const Color(0xFF121212),
        surfaceContainer: const Color(0xFF1E1E1E),
        surfaceContainerHigh: const Color(0xFF252525),
        surfaceContainerHighest: const Color(0xFF2C2C2C),
      ),
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: Colors.black,
      canvasColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF121212),
        surfaceTintColor: Colors.transparent,
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: Color(0xFF121212),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF1E1E1E),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        surfaceTintColor: Colors.transparent,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF121212),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF1E1E1E),
      ),
    );
  }();
}
