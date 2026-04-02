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
import 'package:settings_ui/settings_ui.dart';

// Project imports:
import 'package:safenotes/data/preference_and_config.dart';

class LanguageSetting extends StatefulWidget {
  const LanguageSetting({Key? key}) : super(key: key);

  @override
  State<LanguageSetting> createState() => _LanguageSettingState();
}

class _LanguageSettingState extends State<LanguageSetting> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Language'.tr())),
      body: _settings(),
    );
  }

  Widget _settings() {
    return SettingsList(
      sections: [
        CustomSettingsSection(
          child: CustomSettingsTile(child: _buildLanguageList(context)),
        ),
      ],
    );
  }

  Widget _buildLanguageList(BuildContext context) {
    var selectedIndex = 0;

    if (SafeNotesConfig.mapLocaleName.containsKey(context.locale.toString())) {
      selectedIndex = indexofLanguage(
        SafeNotesConfig.mapLocaleName[context.locale.toString()]!,
      );
    }

    var items = SafeNotesConfig.languageItems;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final isSelected = selectedIndex == index;
            return ListTile(
              title: Text(items[index].prefix),
              subtitle: items[index].helper != null
                  ? Text(items[index].helper!)
                  : null,
              trailing: isSelected
                  ? Icon(Icons.check, color: cs.primary)
                  : null,
              onTap: () => setState(() {
                context.setLocale(
                  SafeNotesConfig.allLocale[items[index].prefix]!,
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

int indexofLanguage(String language) {
  for (var i = 0; i < SafeNotesConfig.languageItems.length; i++) {
    if (SafeNotesConfig.languageItems[i].prefix == language) return i;
  }
  return 0;
}
