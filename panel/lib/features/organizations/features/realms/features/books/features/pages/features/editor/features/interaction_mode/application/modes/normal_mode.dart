import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// The default interaction mode that serves as the baseline experience.
///
/// NormalMode is the default state when the application starts and provides
/// a consistent baseline experience with standard navigation shortcuts.
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
          : Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.5),
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
            priority: 0,
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
        priority: -1,
      ),

      ActionShortcut.intent(
        id: "normal_unselect_selection",
        label: "Unselect Selection",
        description: "Unselect the currently selected item",
        intent: DismissIntent,
        priority: -1,
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

/// Creates an ActionShortcut that transitions to normal mode when escape is pressed.
///
/// This utility function provides a standardized way for modes to include
/// escape-to-normal functionality without implementing it from scratch.
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
