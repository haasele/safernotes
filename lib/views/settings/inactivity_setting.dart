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

class InactivityTimerSetting extends StatefulWidget {
  const InactivityTimerSetting({Key? key}) : super(key: key);

  @override
  State<InactivityTimerSetting> createState() => _InactivityTimerSettingState();
}

class _InactivityTimerSettingState extends State<InactivityTimerSetting> {
  var _selectedIndex = PreferencesStorage.inactivityTimeoutIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Inactivity Timeout'.tr())),
      body: _settings(),
    );
  }

  Widget _settings() {
    return SettingsList(
      sections: [
        SettingsSection(
          tiles: <SettingsTile>[
            SettingsTile.switchTile(
              initialValue: PreferencesStorage.isInactivityTimeoutOn,
              title: Text('Logout upon inactivity'.tr()),
              onToggle: (value) {
                PreferencesStorage.setIsInactivityTimeoutOn(value);
                setState(() {});
              },
              enabled: true,
              description: Text(
                'Close and open app for change to take effect'.tr(),
              ),
            ),
          ],
        ),
        CustomSettingsSection(
          child: CustomSettingsTile(child: _buildTimeList(context)),
        ),
      ],
    );
  }

  Widget _buildTimeList(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: List.generate(items.length, (index) {
            final isSelected = _selectedIndex == index;
            return ListTile(
              title: Text(items[index].prefix),
              subtitle: items[index].helper != null
                  ? Text(items[index].helper!)
                  : null,
              trailing: isSelected
                  ? Icon(Icons.check, color: cs.primary)
                  : null,
              onTap: () => setState(() {
                _selectedIndex = index;
                PreferencesStorage.setInactivityTimeoutIndex(index: index);
              }),
            );
          }),
        ),
      ),
    );
  }
}

class Item {
  final String prefix;
  final String? helper;
  const Item({required this.prefix, this.helper});
}

List<Item> items = [
  Item(prefix: '30 seconds'.tr(), helper: null),
  Item(prefix: '1 minute'.tr(), helper: null),
  Item(prefix: '2 minutes'.tr(), helper: null),
  Item(prefix: '3 minutes'.tr(), helper: 'Default'.tr()),
  Item(prefix: '5 minutes'.tr(), helper: null),
  Item(prefix: '10 minutes'.tr(), helper: null),
  Item(prefix: '15 minutes'.tr(), helper: null),
];
