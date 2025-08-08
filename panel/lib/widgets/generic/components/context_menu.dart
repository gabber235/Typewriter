import "package:flutter/foundation.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/hooks/menu_controller.dart";

part "context_menu.freezed.dart";

class ContextMenuRegion extends HookWidget {
  const ContextMenuRegion({
    required this.items,
    this.enableGestures = true,
    this.controller,
    this.childFocusNode,
    this.child,
    this.builder,
    super.key,
  });

  final List<MenuItem> items;
  final bool enableGestures;

  final MenuController? controller;
  final FocusNode? childFocusNode;

  final Widget? child;
  final Widget Function(BuildContext, MenuController, Widget?)? builder;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller ?? useMenuController();

    final menu = MenuAnchor(
      menuChildren: [
        for (final (index, item) in items.indexed)
          _buildMenuItem(
            context,
            item,
            isFirst: index == 0,
            isLast: index == items.length - 1,
          ),
      ],
      controller: controller,
      childFocusNode: childFocusNode,
      builder: builder,
      child: child,
    );

    if (enableGestures) {
      return GestureDetector(
        onSecondaryTapDown: onSecondaryTapDown(controller),
        onLongPressDown: onLongPressDown(controller),
        onTapDown: onTapDown(controller),
        child: menu,
      );
    }

    return menu;
  }

  static void Function(TapDownDetails) onSecondaryTapDown(
    MenuController controller,
  ) {
    return (details) {
      controller.open(position: details.localPosition);
    };
  }

  static void Function(LongPressDownDetails) onLongPressDown(
    MenuController controller,
  ) {
    return (details) {
      controller.open(position: details.localPosition);
    };
  }

  static void Function() onPress(
    MenuController controller,
  ) {
    return () {
      controller.open();
    };
  }

  static void Function(TapDownDetails) onTapDown(
    MenuController controller, {
    Function(TapDownDetails)? orElse,
  }) {
    return (details) {
      if (controller.isOpen) {
        controller.close();
        return;
      }
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          // Don't open the menu on these platforms with a Ctrl-tap (or a
          // tap).
          orElse?.call(details);
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          // Only open the menu on these platforms if the control button is down
          // when the tap occurs.
          if (HardwareKeyboard.instance.logicalKeysPressed
                  .contains(LogicalKeyboardKey.controlLeft) ||
              HardwareKeyboard.instance.logicalKeysPressed.contains(
                LogicalKeyboardKey.controlRight,
              )) {
            controller.open(position: details.localPosition);
          } else {
            orElse?.call(details);
          }
      }
    };
  }

  Widget _buildMenuItem(
    BuildContext context,
    MenuItem item, {
    required bool isFirst,
    required bool isLast,
  }) {
    final padding = EdgeInsets.only(
      left: 4,
      right: 4,
      top: isFirst ? 4 : 0,
      bottom: isLast ? 4 : 0,
    );
    return switch (item) {
      final MenuItemSubmenu submenu => Padding(
          padding: padding,
          child: SubmenuButton(
            leadingIcon: submenu.icon,
            style: MenuItemButton.styleFrom(
              foregroundColor: submenu.color,
              iconColor: submenu.color,
            ),
            menuChildren: [
              for (final (index, item) in submenu.items.indexed)
                _buildMenuItem(
                  context,
                  item,
                  isFirst: index == 0,
                  isLast: index == submenu.items.length - 1,
                ),
            ],
            child: Text(submenu.label),
          ),
        ),
      MenuItemDivider() => Divider(
          radius: BorderRadiusGeometry.circular(20),
          indent: 4,
          endIndent: 4,
          height: 8,
        ),
      final _MenuItem menuItem => Padding(
          padding: padding,
          child: MenuItemButton(
            autofocus: isFirst,
            leadingIcon: menuItem.icon,
            onPressed: menuItem.onSelected,
            style: MenuItemButton.styleFrom(
              foregroundColor: menuItem.color,
              iconColor: menuItem.color,
              disabledIconColor: menuItem.color?.withValues(alpha: 0.6),
              disabledForegroundColor: menuItem.color?.withValues(alpha: 0.6),
              disabledMouseCursor: SystemMouseCursors.forbidden,
            ),
            child: Text(menuItem.label),
          ),
        ),
      MenuItem _ => const SizedBox.shrink(),
    };
  }
}

@freezed
abstract class MenuItem with _$MenuItem {
  const factory MenuItem({
    required String label,
    Widget? icon,
    Color? color,
    VoidCallback? onSelected,
  }) = _MenuItem;

  const factory MenuItem.submenu({
    required String label,
    required List<MenuItem> items,
    Widget? icon,
    Color? color,
  }) = MenuItemSubmenu;

  const factory MenuItem.divider() = MenuItemDivider;
}
