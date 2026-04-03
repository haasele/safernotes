/*
* Copyright (C) Keshav Priyadarshi and others - All Rights Reserved.
*
* SPDX-License-Identifier: GPL-3.0-or-later
*/

import 'dart:math' as math;
import 'dart:ui';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

/// Draggable frosted bubble that expands into a horizontal format toolbar.
class AppflowyFloatingFormatBar extends StatefulWidget {
  const AppflowyFloatingFormatBar({
    super.key,
    required this.editorState,
    required this.toolbarItems,
    required this.isDark,
    required this.primaryColor,
    required this.onPrimaryColor,
  });

  final EditorState editorState;
  final List<MobileToolbarItem> toolbarItems;
  final bool isDark;
  final Color primaryColor;
  final Color onPrimaryColor;

  @override
  State<AppflowyFloatingFormatBar> createState() =>
      _AppflowyFloatingFormatBarState();
}

class _SheetMenuSvc implements MobileToolbarWidgetService {
  _SheetMenuSvc(this._pop);
  final void Function() _pop;
  @override
  void closeItemMenu() => _pop();
}

class _NoOpMobileToolbarSvc implements MobileToolbarWidgetService {
  @override
  void closeItemMenu() {}
}

class _AppflowyFloatingFormatBarState extends State<AppflowyFloatingFormatBar> {
  bool _expanded = false;
  Offset _drag = Offset.zero;

  static const double _collapsed = 56;
  static const double _expandedHeight = 58;

  Color get _glassFill => widget.isDark
      ? Colors.black.withValues(alpha: 0.42)
      : Colors.white.withValues(alpha: 0.75);

  Color get _iconColor => widget.isDark ? Colors.white : const Color(0xFF1A1A1A);

  MobileToolbarTheme _toolbarTheme(Widget child) {
    final barBg =
        widget.isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5);
    final barFg = _iconColor;
    return MobileToolbarTheme(
      backgroundColor: barBg,
      foregroundColor: barFg,
      iconColor: barFg,
      clearDiagonalLineColor: const Color(0xffB3261E),
      itemHighlightColor: widget.primaryColor,
      itemOutlineColor:
          widget.isDark ? Colors.white24 : const Color(0xFFE3E3E3),
      tabBarSelectedBackgroundColor: barFg.withValues(alpha: 0.12),
      tabBarSelectedForegroundColor: barFg,
      primaryColor: widget.primaryColor,
      onPrimaryColor: widget.onPrimaryColor,
      outlineColor:
          widget.isDark ? Colors.white24 : const Color(0xFFE3E3E3),
      child: child,
    );
  }

  void _openItemMenu(MobileToolbarItem item) {
    if (!item.hasMenu || item.itemMenuBuilder == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: _toolbarTheme(
            item.itemMenuBuilder!(
                  ctx,
                  widget.editorState,
                  _SheetMenuSvc(() {
                    if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
                  }),
                ) ??
                const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final insetBottom = mq.padding.bottom + mq.viewInsets.bottom;
    final sw = mq.size.width;
    final sh = mq.size.height;

    final width =
        _expanded ? math.min(340, sw - 24).toDouble() : _collapsed;
    final height = _expanded ? _expandedHeight : _collapsed;

    var left = (sw - width) / 2 + _drag.dx;
    var bottom = insetBottom + 16 + _drag.dy;
    left = left.clamp(12.0, math.max(12, sw - width - 12));
    bottom = bottom.clamp(12.0, math.max(12, sh - height - mq.padding.top - 80));

    return Positioned(
      left: left,
      bottom: bottom,
      width: width,
      height: height,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _drag += details.delta;
          });
        },
        child: _toolbarTheme(
          ClipRRect(
            borderRadius:
                BorderRadius.circular(_expanded ? 22 : _collapsed / 2),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: _glassFill,
                  borderRadius:
                      BorderRadius.circular(_expanded ? 22 : _collapsed / 2),
                  border: Border.all(
                    color: Colors.white
                        .withValues(alpha: widget.isDark ? 0.14 : 0.45),
                  ),
                ),
                child: _expanded
                    ? _buildExpanded(context)
                    : _buildCollapsed(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsed(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => setState(() => _expanded = true),
        child: Center(
          child: Icon(
            Icons.auto_fix_high_rounded,
            color: _iconColor,
            size: 26,
          ),
        ),
      ),
    );
  }

  Widget _buildExpanded(BuildContext context) {
    final svc = _NoOpMobileToolbarSvc();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: _expandedHeight - 8,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.toolbarItems.length,
                separatorBuilder: (_, _) => const SizedBox(width: 2),
                itemBuilder: (context, index) {
                  final item = widget.toolbarItems[index];
                  final icon = item.itemIconBuilder?.call(
                    context,
                    widget.editorState,
                    svc,
                  );
                  if (icon == null) return const SizedBox.shrink();
                  return IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    icon: icon,
                    onPressed: () {
                      if (item.hasMenu) {
                        _openItemMenu(item);
                      } else {
                        item.actionHandler?.call(context, widget.editorState);
                      }
                    },
                  );
                },
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: _iconColor),
            onPressed: () => setState(() => _expanded = false),
          ),
        ],
      ),
    );
  }
}
