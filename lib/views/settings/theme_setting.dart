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

// Project imports:
import 'package:safenotes/models/app_theme.dart';

void showThemeBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) => const ThemeBottomSheet(),
  );
}

class ThemeBottomSheet extends StatelessWidget {
  const ThemeBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ThemeProvider>(context);
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Dark theme'.tr(),
              style: tt.titleLarge,
            ),
            const SizedBox(height: 8),
            RadioGroup<ThemeFlavor>(
              groupValue: provider.flavor,
              onChanged: (ThemeFlavor? v) {
                if (v == null) return;
                Provider.of<ThemeProvider>(context, listen: false)
                    .setFlavor(v);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<ThemeFlavor>(
                    title: Text('Use device settings'.tr()),
                    value: ThemeFlavor.system,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  RadioListTile<ThemeFlavor>(
                    title: Text('Material You light'.tr()),
                    value: ThemeFlavor.materialYouLight,
                  ),
                  RadioListTile<ThemeFlavor>(
                    title: Text('Material You dark'.tr()),
                    value: ThemeFlavor.materialYouDark,
                  ),
                  RadioListTile<ThemeFlavor>(
                    title: Text('Pitch Black'.tr()),
                    value: ThemeFlavor.pitchBlack,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
