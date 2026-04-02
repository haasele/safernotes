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

class ExpandableFab extends StatefulWidget {
  final List<FabOption> options;

  const ExpandableFab({
    super.key,
    required this.options,
  });

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _close() {
    if (_isOpen) {
      setState(() => _isOpen = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ..._buildOptions(cs),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'mainFab',
          onPressed: _toggle,
          child: AnimatedBuilder(
            animation: _expandAnimation,
            builder: (_, child) => Transform.rotate(
              angle: _expandAnimation.value * 0.75,
              child: child,
            ),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildOptions(ColorScheme cs) {
    final options = <Widget>[];
    for (var i = widget.options.length - 1; i >= 0; i--) {
      final option = widget.options[i];
      options.add(
        FadeTransition(
          opacity: _expandAnimation,
          child: ScaleTransition(
            scale: _expandAnimation,
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(8),
                    color: cs.surfaceContainerHigh,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text(
                        option.label,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton.small(
                    heroTag: 'fab_$i',
                    backgroundColor: cs.primaryContainer,
                    foregroundColor: cs.onPrimaryContainer,
                    onPressed: () {
                      _close();
                      option.onPressed();
                    },
                    child: Icon(option.icon),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return options;
  }
}

class FabOption {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const FabOption({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
}

List<FabOption> buildNoteCreationOptions({
  required VoidCallback onText,
  required VoidCallback onAudio,
  required VoidCallback onImage,
  required VoidCallback onDrawing,
  required VoidCallback onChecklist,
}) {
  return [
    FabOption(
      icon: Icons.edit_note,
      label: 'Text Note'.tr(),
      onPressed: onText,
    ),
    FabOption(
      icon: Icons.mic,
      label: 'Audio Note'.tr(),
      onPressed: onAudio,
    ),
    FabOption(
      icon: Icons.image,
      label: 'Image Note'.tr(),
      onPressed: onImage,
    ),
    FabOption(
      icon: Icons.brush,
      label: 'Drawing'.tr(),
      onPressed: onDrawing,
    ),
    FabOption(
      icon: Icons.checklist,
      label: 'Checklist'.tr(),
      onPressed: onChecklist,
    ),
  ];
}
