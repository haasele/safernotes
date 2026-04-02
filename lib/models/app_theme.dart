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
  ColorScheme? _dynamicLight;
  ColorScheme? _dynamicDark;

  ThemeFlavor get flavor => _flavor;
  ColorScheme? get dynamicLight => _dynamicLight;
  ColorScheme? get dynamicDark => _dynamicDark;

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

  ThemeData get lightTheme {
    if (_dynamicLight != null) {
      return ThemeData(useMaterial3: true, colorScheme: _dynamicLight);
    }
    return AppThemes.materialYouLight;
  }

  ThemeData get darkTheme {
    if (_flavor == ThemeFlavor.pitchBlack) {
      return AppThemes.buildPitchBlack(_dynamicDark);
    }
    if (_dynamicDark != null) {
      return ThemeData(useMaterial3: true, colorScheme: _dynamicDark);
    }
    return AppThemes.materialYouDark;
  }

  void setDynamicSchemes(ColorScheme? light, ColorScheme? dark) {
    _dynamicLight = light;
    _dynamicDark = dark;
    notifyListeners();
  }

  void setFlavor(ThemeFlavor flavor) {
    _flavor = flavor;
    PreferencesStorage.setThemeFlavor(flavor.index);
    notifyListeners();
  }
}

class AppThemes {
  static const Color seedColor = Color(0xFF88C0D0);

  static final ThemeData materialYouLight = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    ),
  );

  static final ThemeData materialYouDark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    ),
  );

  static ThemeData buildPitchBlack(ColorScheme? baseDynamic) {
    final baseScheme = baseDynamic ??
        ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: baseScheme.copyWith(
        surface: Colors.black,
        onSurface: Colors.white,
        surfaceContainerLowest: Colors.black,
        surfaceContainerLow: Colors.black,
        surfaceContainer: Colors.black,
        surfaceContainerHigh: Colors.black,
        surfaceContainerHighest: const Color(0xFF121212),
      ),
      scaffoldBackgroundColor: Colors.black,
      canvasColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: Colors.black,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.black,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.black,
      ),
      cardTheme: const CardThemeData(
        color: Colors.black,
      ),
    );
  }
}
