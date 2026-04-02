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
import 'package:safenotes_nord_theme/safenotes_nord_theme.dart';

// Project imports:
import 'package:safenotes/data/preference_and_config.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode themeMode =
      PreferencesStorage.isThemeDark ? ThemeMode.dark : ThemeMode.light;

  bool get isDarkMode => themeMode == ThemeMode.dark;

  void setIsDarkMode(bool isDark) {
    themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    PreferencesStorage.setIsThemeDark(isDark);
    notifyListeners();
  }

  void setIsDarkDimTheme(bool isDim) {
    //themeMode = isDim ? ThemeMode.dark : ThemeMode.light;
    PreferencesStorage.setIsDimTheme(isDim);
    notifyListeners();
  }
}

class AppThemes {
  // Material You seed colors based on Nord theme palette
  // Using Nord's polar night blue (#2E3440) and frost blue (#88C0D0) as seed colors
  static const Color _lightSeedColor = Color(0xFF88C0D0); // Nord frost blue
  static const Color _darkSeedColor =
      Color(0xFF5E81AC); // Nord polar night blue variant

  //static final ThemeData darkTheme = ThemeData.dark();
  static ThemeData get darkTheme =>
      PreferencesStorage.isDimTheme ? dimTheme : lightOutTheme;

  static final ThemeData lightOutTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _darkSeedColor,
      brightness: Brightness.dark,
    ).copyWith(
      surface: Colors.black,
      onSurface: Colors.white,
      surfaceContainerHighest: Colors.grey.shade900,
      surfaceContainer: Colors.grey.shade800,
      surfaceContainerLow: Colors.grey.shade700,
    ),
    textTheme: ThemeData.dark().textTheme.apply(
          fontFamily: 'NotoSerif',
        ),
    primaryTextTheme: ThemeData.dark().textTheme.apply(
          fontFamily: 'NotoSerif',
        ),
    bottomAppBarTheme: BottomAppBarThemeData(
      color: Colors.grey.shade900,
    ),
    dialogBackgroundColor: Colors.grey.shade900,
    scaffoldBackgroundColor: Colors.black,
    canvasColor: Colors.black,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey.shade900,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.grey.shade900,
      surfaceTintColor: Colors.transparent,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: Colors.grey.shade900,
    ),
  );

  static final ThemeData dimTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _darkSeedColor,
      brightness: Brightness.dark,
    ),
    textTheme: ThemeData.dark().textTheme.apply(
          fontFamily: 'NotoSerif',
        ),
    primaryTextTheme: ThemeData.dark().textTheme.apply(
          fontFamily: 'NotoSerif',
        ),
  );

  static Color get darkSettingsScaffold => PreferencesStorage.isDimTheme
      ? NordColors.polarNight.darkest
      : Colors.black;

  static Color? get darkSettingsCanvas => PreferencesStorage.isDimTheme
      ? NordColors.polarNight.darker
      : Colors.grey.shade900;

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _lightSeedColor,
      brightness: Brightness.light,
    ),
    textTheme: ThemeData.light().textTheme.apply(
          fontFamily: 'NotoSerif',
        ),
    primaryTextTheme: ThemeData.light().textTheme.apply(
          fontFamily: 'NotoSerif',
        ),
    unselectedWidgetColor: NordColors.frost.darker,
  );
}
