import "package:typewriter_panel/typewriter_panel.dart";

part "context_menu.freezed.dart";

/// What assistive technology calls an open context menu.
const contextMenuSemanticLabel = "Context menu";

/// Adds a platform aware context menu to a child widget.
///
/// Secondary click and long press open the menu at the pointer position when
/// [enableGestures] is true. On Apple platforms, a control click opens it;
/// other taps can be delegated through the static [onTapUp] helper's `orElse`
/// callback. Supply [builder] when the child must be built with the menu
/// controller. The menu sits on [AnchoredPopup], so it grows out of the
/// pointer with panelIn and leaves with panelOut.
class ContextMenuRegion extends HookWidget {
  const ContextMenuRegion({
    required this.items,
    this.enableGestures = true,
    this.controller,
    this.onClose,
    this.child,
    this.builder,
    super.key,
  }) : assert(
         items.length > 0 || builder == null,
         "You cannot have a builder with no items",
       );

  final List<MenuItem> items;
  final bool enableGestures;

  final AnchoredPopupController? controller;
  final VoidCallback? onClose;

  final Widget? child;
  final Widget Function(BuildContext, AnchoredPopupController, Widget?)?
  builder;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return child ?? const SizedBox.shrink();

    final owned = useMemoized(AnchoredPopupController.new);
    useEffect(() => owned.dispose, [owned]);
    final controller = this.controller ?? owned;
    final wasOpen = useRef(controller.isOpen);
    useEffect(() {
      void closed() {
        if (wasOpen.value && !controller.isOpen) onClose?.call();
        wasOpen.value = controller.isOpen;
      }

      controller.addListener(closed);
      return () => controller.removeListener(closed);
    }, [controller, onClose]);

    final anchor = AnchoredPopup(
      controller: controller,
      opensOnHover: false,
      // Names the open menu for assistive technology, which reads it out
      // before its entries.
      semanticLabel: contextMenuSemanticLabel,
      builder: (context, show) =>
          builder?.call(context, controller, child) ??
          child ??
          const SizedBox.shrink(),
      popupBuilder: (context, close) => _MenuItems(items: items, close: close),
    );

    final menu = Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.contextMenu):
            SelectorContextMenuIntent(),
        SingleActivator(LogicalKeyboardKey.f10, shift: true):
            SelectorContextMenuIntent(),
      },
      child: Actions(
        actions: {
          SelectorContextMenuIntent: CallbackAction<SelectorContextMenuIntent>(
            onInvoke: (_) {
              controller.openFocused();
              return null;
            },
          ),
        },
        child: anchor,
      ),
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
    AnchoredPopupController controller,
  ) {
    return (details) => controller.openAt(details.localPosition);
  }

  /// Creates a long press handler that opens [controller] at the pointer.
  static void Function(LongPressStartDetails) onLongPressStart(
    AnchoredPopupController controller,
  ) {
    return (details) => controller.openAt(details.localPosition);
  }

  /// Creates a toggle handler for controls that open the menu themselves.
  static void Function() onPress(AnchoredPopupController controller) {
    return () {
      if (controller.isOpen) {
        controller.close();
        return;
      }
      controller.openFocused();
    };
  }

  /// Creates a tap handler that applies the platform context menu policy.
  ///
  /// [onContextTap] replaces menu opening on an Apple Control click. It must
  /// resolve the target and open the menu itself if needed.
  static void Function(TapUpDetails) onTapUp(
    AnchoredPopupController controller, {
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
              controller.openAt(details.localPosition);
            }
          } else {
            orElse?.call(details);
          }
      }
    };
  }
}

/// The entries of one menu level; choosing an entry runs its action, then
/// closes the whole menu through [close].
class _MenuItems extends StatelessWidget {
  const _MenuItems({required this.items, required this.close});

  final List<MenuItem> items;
  final VoidCallback close;

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.space1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final item in items) _item(context, item)],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, MenuItem item) => switch (item) {
    final MenuItemSubmenu submenu => _Submenu(submenu: submenu, close: close),
    final MenuItemSection section => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (section.label != null)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.space2,
              vertical: context.spacing.space1,
            ),
            child: DefaultTextStyle(
              style: context.theme.textTheme.labelSmall!.copyWith(
                color: section.color ?? context.colors.contentSecondary,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: context.spacing.space1,
                children: [
                  if (section.icon != null)
                    IconTheme(
                      data: IconThemeData(
                        size: 14,
                        color: section.color ?? context.colors.contentSecondary,
                      ),
                      child: section.icon!,
                    ),
                  Text(section.label!),
                ],
              ),
            ),
          ),
        for (final item in section.items) _item(context, item),
      ],
    ),
    MenuItemDivider() => Padding(
      padding: EdgeInsets.symmetric(vertical: context.spacing.space1),
      child: SizedBox(
        height: 1,
        child: ColoredBox(
          color: context.colors.contentSecondary.withValues(alpha: 0.2),
        ),
      ),
    ),
    final _MenuItem entry => PanelMenuItem(
      label: entry.label,
      leading: entry.icon,
      color: entry.color,
      enabled: entry.onPressed != null,
      trailing: entry.shortcuts.isEmpty
          ? null
          : ShortcutDisplay(shortcut: entry.shortcuts.first),
      // The action runs first: closing ends the menu's context targets.
      onPressed: () {
        entry.onPressed?.call();
        close();
      },
    ),
    MenuItem _ => const SizedBox.shrink(),
  };
}

/// A submenu row: it previews its entries beside it on hover and opens them
/// focused when chosen; RawMenuAnchor closes it with its parent.
class _Submenu extends HookWidget {
  const _Submenu({required this.submenu, required this.close});

  final MenuItemSubmenu submenu;
  final VoidCallback close;

  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(AnchoredPopupController.new);
    useEffect(() => controller.dispose, [controller]);
    return AnchoredPopup(
      controller: controller,
      targetAnchor: Alignment.topRight,
      popupAnchor: Alignment.topLeft,
      builder: (context, show) => PanelMenuItem(
        label: submenu.label,
        leading: submenu.icon,
        color: submenu.color,
        trailing: const Icon(Icons.chevron_right),
        onPressed: show,
      ),
      popupBuilder: (context, _) =>
          _MenuItems(items: submenu.items, close: close),
    );
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
