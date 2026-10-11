import "package:typewriter_panel/typewriter_panel.dart";

part "context_menu.freezed.dart";

/// Adds a platform aware context menu to a child widget.
///
/// Secondary click and long press open the menu at the pointer position when
/// [enableGestures] is true. On Apple platforms, a control click opens it;
/// other taps are delegated to [onTapUp]'s [orElse] callback. Supply [builder]
/// when the child must be built with the menu controller.
class ContextMenuRegion extends HookWidget {
  const ContextMenuRegion({
    required this.items,
    this.enableGestures = true,
    this.controller,
    this.childFocusNode,
    this.child,
    this.builder,
    super.key,
  }) : assert(
         items.length > 0 || builder == null,
         "You cannot have a builder with no items",
       );

  final List<MenuItem> items;
  final bool enableGestures;

  final MenuController? controller;
  final FocusNode? childFocusNode;

  final Widget? child;
  final Widget Function(BuildContext, MenuController, Widget?)? builder;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return child ?? const SizedBox.shrink();

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
        onSecondaryTapUp: onSecondaryTapUp(controller),
        onLongPressStart: onLongPressStart(controller),
        onTapUp: onTapUp(controller),
        child: menu,
      );
    }

    return menu;
  }

  /// Creates a secondary click handler that opens [controller] at the pointer.
  static void Function(TapUpDetails) onSecondaryTapUp(
    MenuController controller,
  ) {
    return (details) {
      controller.open(position: details.localPosition);
    };
  }

  /// Creates a long press handler that opens [controller] at the pointer.
  static void Function(LongPressStartDetails) onLongPressStart(
    MenuController controller,
  ) {
    return (details) {
      controller.open(position: details.localPosition);
    };
  }

  /// Creates a toggle handler for controls that open the menu themselves.
  static void Function() onPress(MenuController controller) {
    return () {
      if (controller.isOpen) {
        controller.close();
        return;
      }
      controller.open();
    };
  }

  /// Creates a tap handler that applies the platform context menu policy.
  ///
  /// Supply [onContextTap] to resolve a target before opening its actions.
  static void Function(TapUpDetails) onTapUp(
    MenuController controller, {
    Function(TapUpDetails)? orElse,
    ValueChanged<TapUpDetails>? onContextTap,
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
          // Don't open the menu on these platforms with a Ctrl tap (or a
          // tap).
          orElse?.call(details);
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          // Only open the menu on these platforms if the control button is down
          // when the tap occurs.
          if (HardwareKeyboard.instance.logicalKeysPressed.contains(
                LogicalKeyboardKey.controlLeft,
              ) ||
              HardwareKeyboard.instance.logicalKeysPressed.contains(
                LogicalKeyboardKey.controlRight,
              )) {
            if (onContextTap != null) {
              onContextTap(details);
            } else {
              controller.open(position: details.localPosition);
            }
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
      left: context.spacing.space1,
      right: context.spacing.space1,
      top: isFirst ? context.spacing.space1 : 0,
      bottom: isLast ? context.spacing.space1 : 0,
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
      final MenuItemSection section => Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (section.label != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.spacing.space2,
                  context.spacing.space1,
                  context.spacing.space2,
                  context.spacing.space1,
                ),
                child: DefaultTextStyle(
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color:
                        section.color ??
                        Theme.of(context).colorScheme.onSurface
                            .withValues(alpha: 0.6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (section.icon != null) ...[
                        IconTheme(
                          data: IconThemeData(
                            size: 14,
                            color:
                                section.color ??
                                Theme.of(context).colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                          ),
                          child: section.icon!,
                        ),
                        SizedBox(width: context.spacing.space1),
                      ],
                      Text(section.label!),
                    ],
                  ),
                ),
              ),
            for (final (index, item) in section.items.indexed)
              _buildMenuItem(
                context,
                item,
                isFirst: index == 0,
                isLast: index == section.items.length - 1,
              ),
          ],
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
          onPressed: menuItem.onPressed,
          style: MenuItemButton.styleFrom(
            foregroundColor: menuItem.color,
            iconColor: menuItem.color,
            disabledIconColor: menuItem.color?.withValues(alpha: 0.6),
            disabledForegroundColor: menuItem.color?.withValues(alpha: 0.6),
            disabledMouseCursor: SystemMouseCursors.forbidden,
          ),
          child: Row(
            spacing: context.spacing.space2,
            children: [
              Expanded(child: Text(menuItem.label, maxLines: 1)),
              if (menuItem.shortcuts.isNotEmpty) ...[
                RotatingShortcuts(shortcuts: menuItem.shortcuts),
              ],
            ],
          ),
        ),
      ),
      MenuItem _ => const SizedBox.shrink(),
    };
  }
}

/// Describes one entry, group, submenu, or divider in a [ContextMenuRegion].
///
/// Menu entries invoke [onPressed] when selected. A submenu and section own
/// their nested entries and must contain at least one item.
@freezed
abstract class MenuItem with _$MenuItem {
  @Assert("label != \"\"", "Label must not be empty.")
  /// Creates an actionable menu entry. A null [onPressed] disables it.
  const factory MenuItem({
    required String label,
    Widget? icon,
    Color? color,
    VoidCallback? onPressed,
    @Default([]) List<ShortcutActivator> shortcuts,
  }) = _MenuItem;

  @Assert("label != \"\"", "Label must not be empty.")
  @Assert("items.length > 0", "Items must not be empty.")
  /// Creates a labeled submenu containing [items].
  const factory MenuItem.submenu({
    required String label,
    required List<MenuItem> items,
    Widget? icon,
    Color? color,
  }) = MenuItemSubmenu;

  @Assert("items.length > 0", "Items must not be empty.")
  @Assert("label == null || label != \"\"", "Label must be null or nonempty.")
  /// Creates a grouped set of entries with an optional heading.
  const factory MenuItem.section({
    required List<MenuItem> items,
    String? label,
    Widget? icon,
    Color? color,
  }) = MenuItemSection;

  /// Creates a visual separator between neighboring entries.
  const factory MenuItem.divider() = MenuItemDivider;
}
