import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:typewriter_panel/typewriter_panel.dart";

export "action_shortcuts.dart";

/// The panel wide keyboard map used by `MaterialApp.router` and action sets.
///
/// Entries may use [AdaptiveSingleActivator] so control on one platform maps
/// to meta on another. Intent based actions resolve their display activators
/// through this map, which keeps registration and shortcut hints consistent.
final typewriterShortcuts = <ShortcutActivator, Intent>{
  ...WidgetsApp.defaultShortcuts,

  SingleActivator(LogicalKeyboardKey.enter, shift: true): ActivateAllIntent(),
  SingleActivator(LogicalKeyboardKey.numpadEnter, shift: true):
      ActivateAllIntent(),
  SingleActivator(LogicalKeyboardKey.space, shift: true): ActivateAllIntent(),

  AdaptiveSingleActivator(
    LogicalKeyboardKey.enter,
    control: true,
    includeRepeats: false,
  ): PrimaryActionIntent(),
  AdaptiveSingleActivator(
    LogicalKeyboardKey.numpadEnter,
    control: true,
    includeRepeats: false,
  ): PrimaryActionIntent(),

  AdaptiveSingleActivator(LogicalKeyboardKey.escape, control: true):
      CancelIntent(),

  SingleActivator(LogicalKeyboardKey.keyN, control: true): NextFocusIntent(),
  SingleActivator(LogicalKeyboardKey.keyP, control: true):
      PreviousFocusIntent(),

  SingleActivator(LogicalKeyboardKey.home): FirstItemIntent(),
  SingleActivator(LogicalKeyboardKey.end): LastItemIntent(),

  SingleActivator(LogicalKeyboardKey.pageUp): ScrollIntent(
    direction: AxisDirection.down,
    type: ScrollIncrementType.page,
  ),
  SingleActivator(LogicalKeyboardKey.pageDown): ScrollIntent(
    direction: AxisDirection.up,
    type: ScrollIncrementType.page,
  ),
  AdaptiveSingleActivator(LogicalKeyboardKey.keyU, control: true): ScrollIntent(
    direction: AxisDirection.up,
    type: ScrollIncrementType.page,
  ),
  AdaptiveSingleActivator(LogicalKeyboardKey.keyD, control: true): ScrollIntent(
    direction: AxisDirection.down,
    type: ScrollIncrementType.page,
  ),

  SingleActivator(LogicalKeyboardKey.keyH, control: true): NavigatePaneIntent(
    AxisDirection.left,
  ),
  SingleActivator(LogicalKeyboardKey.keyL, control: true): NavigatePaneIntent(
    AxisDirection.right,
  ),
  SingleActivator(LogicalKeyboardKey.keyJ, control: true): NavigatePaneIntent(
    AxisDirection.down,
  ),
  AdaptiveSingleActivator(LogicalKeyboardKey.keyK, control: true):
      OpenSearchIntent(),
  SingleActivator(LogicalKeyboardKey.arrowLeft, control: true):
      NavigatePaneIntent(AxisDirection.left),
  SingleActivator(LogicalKeyboardKey.arrowRight, control: true):
      NavigatePaneIntent(AxisDirection.right),
  SingleActivator(LogicalKeyboardKey.arrowDown, control: true):
      NavigatePaneIntent(AxisDirection.down),
  SingleActivator(LogicalKeyboardKey.arrowUp, control: true):
      NavigatePaneIntent(AxisDirection.up),

  SingleActivator(LogicalKeyboardKey.keyD): DeleteIntent(),
  SingleActivator(LogicalKeyboardKey.backspace): DeleteIntent(),
  SingleActivator(LogicalKeyboardKey.delete): DeleteIntent(),
  SingleActivator(LogicalKeyboardKey.keyX): DeleteIntent(),
  SingleActivator(LogicalKeyboardKey.keyD, shift: true): DeleteIntent(),
  SingleActivator(LogicalKeyboardKey.backspace, shift: true): DeleteIntent(),
  SingleActivator(LogicalKeyboardKey.delete, shift: true): DeleteIntent(),
  SingleActivator(LogicalKeyboardKey.keyX, shift: true): DeleteIntent(),
};

final movementShortcuts = {
  [LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.keyK]: TraversalDirection.up,
  [LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.keyJ]:
      TraversalDirection.down,
  [LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyH]:
      TraversalDirection.left,
  [LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyL]:
      TraversalDirection.right,
};

/// Activates every currently applicable action in the focused context.
class ActivateAllIntent extends Intent {
  const ActivateAllIntent();
}

/// Intentionally discards the current edit, unlike [DismissIntent] which
/// leaves a field while keeping what was typed.
class CancelIntent extends Intent {
  const CancelIntent();
}

/// Requests deletion of the focused or selected item.
class DeleteIntent extends Intent {
  const DeleteIntent();
}

/// Moves focus or selection to the first item in the current collection.
class FirstItemIntent extends Intent {
  const FirstItemIntent();
}

/// Moves focus or selection to the last item in the current collection.
class LastItemIntent extends Intent {
  const LastItemIntent();
}

/// Invokes the primary action for the focused surface.
class PrimaryActionIntent extends Intent {
  const PrimaryActionIntent();
}

/// Opens the application primary search surface.
class OpenSearchIntent extends Intent {
  const OpenSearchIntent();
}

/// Returns activators whose mapped intent has exactly [intent].
List<ShortcutActivator> shortcutsFor(Type intent) {
  return typewriterShortcuts.entries
      .where((entry) => entry.value.runtimeType == intent)
      .map((entry) => entry.key)
      .toList();
}

/// Returns activators for [I] whose intent satisfies [predicate].
List<ShortcutActivator> shortcutsForIntent<I extends Intent>(
  bool Function(I intent) predicate,
) {
  return typewriterShortcuts.entries
      .where((entry) => entry.value is I && predicate(entry.value as I))
      .map((entry) => entry.key)
      .toList();
}
