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
import 'package:any_link_preview/any_link_preview.dart';

// Project imports:
import 'package:safenotes/data/preference_and_config.dart';

class RichLinkPreviewWidget extends StatelessWidget {
  final String url;

  const RichLinkPreviewWidget({
    super.key,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    if (!PreferencesStorage.isRichLinkPreview) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: AnyLinkPreview(
        link: url,
        displayDirection: UIDirection.uiDirectionHorizontal,
        bodyMaxLines: 3,
        bodyTextOverflow: TextOverflow.ellipsis,
        titleStyle: TextStyle(
          color: cs.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        bodyStyle: TextStyle(
          color: cs.onSurfaceVariant,
          fontSize: 12,
        ),
        backgroundColor: isDark
            ? cs.surfaceContainerHigh
            : cs.surfaceContainerLow,
        borderRadius: 12,
        boxShadow: const [],
        errorBody: '',
        errorTitle: '',
        errorWidget: const SizedBox.shrink(),
      ),
    );
  }
}
