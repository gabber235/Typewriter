import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// The default interaction mode that serves as the baseline experience.
///
/// The mode used when no specialized interaction owns focus.
///
/// It is the provider's initial state and the destination for dismiss and
/// cancel transitions. Its shortcuts cover directional focus movement and
/// selection clearing. It also supplies the app bar display for this baseline
/// context.
class NormalMode extends InteractionMode
    with ModeDisplay, ModeShortcut, DirectionalInteractionMode {
  const NormalMode();

  @override
  String get name => "Normal";

  @override
  Widget buildDisplay(BuildContext context) {
    return ModeDisplayChip(
      label: "Normal",
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: context.isDarkMode
          ? null
          : Theme.of(context).colorScheme.primaryContainer
                .withValues(alpha: 0.5),
    );
  }

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
            onInvoke: (ref) => invokeCurrentModeDirection(ref, direction),
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

      ActionShortcut.intent(
        id: "normal_unselect_selection",
        label: "Unselect Selection",
        description: "Unselect the currently selected item",
        intent: DismissIntent,
        priority: -11,
        show: false,
        onInvoke: (ref) {
          final focused = SelectableScope.primaryFocusedId();
          if (focused == null) {
            ref.read(selectionProvider.notifier).clear();
            return;
          }

          final selection = ref.read(selectionProvider);
          if (selection.isEmpty) return;
          if (selection.length == 1) {
            ref.read(selectionProvider.notifier).clear();
            return;
          }
          ref
              .read(selectionProvider.notifier)
              .select(focused, isMultiSelect: false);
        },
      ),
    ];
  }

  @override
  Intent intentForDirection(TraversalDirection direction) =>
      DirectionalFocusIntent(direction);
}

/// Creates the shared Escape action that returns the panel to [NormalMode].
///
/// [onInvoke] runs first when supplied. The final transition to normal mode is
/// unconditional, so a callback cannot leave a specialized mode active.
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
  return ActionShortcut.intent(
    id: "escape_to_normal",
    label: "Normal Mode",
    description: "Return to normal mode",
    intent: DismissIntent,
    priority: 1000,
    onInvoke: (ref) {
      onInvoke?.call(ref);
      ref.read(currentInteractionModeProvider.notifier).normal();
    },
  );
}
