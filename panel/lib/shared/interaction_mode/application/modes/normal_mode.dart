import "package:typewriter_panel/typewriter_panel.dart";

/// The default interaction mode that serves as the baseline experience.
///
/// The mode used when no specialized interaction owns focus.
///
/// It is the provider's initial state and the destination for dismiss and
/// cancel transitions. Its shortcuts cover directional focus movement.
/// Selection clearing belongs to `GlobalOperationShortcuts`. It also supplies
/// the app bar display for this baseline context.
class NormalMode extends InteractionMode
    with ModeDisplay, ModeShortcut, DirectionalInteractionMode {
  const NormalMode();

  @override
  String get name => "Normal";

  @override
  ModeLook look(BuildContext context) =>
      ModeLook(label: "Normal", tone: context.colors.brand, soft: true);

  @override
  List<ActionShortcut> getShortcuts() {
    return [
      for (final MapEntry(key: keys, value: direction)
          in movementShortcuts.entries)
        for (final key in keys)
          ActionShortcut(
            id: "normal_move_${direction.name}_${key.debugName?.snakeCase()}",
            label: "Move Focus ${direction.name.titleCase()}",
            description: "Move focus ${direction.name}",
            activators: [SingleActivator(key)],
            priority: -10,
            show: false,
            run: ActionRun.press(
              (ref) => invokeCurrentModeDirection(ref, direction),
            ),
          ),

      // Display
      ActionShortcut(
        id: "normal_switch_focus",
        label: "Switch Focus",
        description: "Move between focusable elements in the UI",
        activators: [
          SortedLogicalKeyActivator.fromList([
            LogicalKeyboardKey.arrowLeft,
            LogicalKeyboardKey.arrowDown,
            LogicalKeyboardKey.arrowUp,
            LogicalKeyboardKey.arrowRight,
          ]),
          SortedLogicalKeyActivator.fromList([
            LogicalKeyboardKey.keyH,
            LogicalKeyboardKey.keyJ,
            LogicalKeyboardKey.keyK,
            LogicalKeyboardKey.keyL,
          ]),
          SingleActivator(LogicalKeyboardKey.tab),
          SingleActivator(LogicalKeyboardKey.tab, shift: true),
        ],
        priority: -11,
      ),
    ];
  }

  @override
  Intent intentForDirection(TraversalDirection direction) =>
      DirectionalFocusIntent(direction);
}

/// Creates the shared Escape action that returns the panel to [NormalMode].
///
/// Escape first dismisses what the focused widget can dismiss below the
/// nearest [GlobalModeShortcut], such as an input field; only when nothing
/// there accepts it does the mode end. The action binds Escape directly
/// instead of [DismissIntent]: a page route answers [DismissIntent] with its
/// own disabled dismiss action, which would otherwise swallow the key.
///
/// [onInvoke] is invoked before the transition. Its returned value is ignored,
/// so asynchronous work does not delay the transition. A synchronous exception
/// prevents the transition and propagates to the action caller.
///
/// Example usage:
/// ```dart
/// class MyMode extends InteractionMode with ModeShortcut {
///   @override
///   List<ActionShortcut> getShortcuts() {
///     return [
///       // ... other shortcuts
///       escapeToNormalAction(),
///     ];
///   }
/// }
/// ```
ActionShortcut escapeToNormalAction({Function(WidgetRef ref)? onInvoke}) {
  return ActionShortcut(
    id: "escape_to_normal",
    label: "Normal Mode",
    description: "Return to normal mode",
    activators: const [SingleActivator(LogicalKeyboardKey.escape)],
    priority: 1000,
    run: ActionRun.press((ref) {
      if (GlobalModeShortcut.dismissFocused()) return;
      onInvoke?.call(ref);
      ref.read(currentInteractionModeProvider.notifier).normal();
    }),
  );
}
