import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:typewriter_panel/app/presentation/shell/panes.dart";
import "package:typewriter_panel/shared/utilities/adaptive_single_activator.dart";

final typewriterShortcuts = <ShortcutActivator, Intent>{
  ...WidgetsApp.defaultShortcuts,

  SingleActivator(LogicalKeyboardKey.enter, shift: true): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.numpadEnter, shift: true):
      ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.space, shift: true): ActivateIntent(),

  AdaptiveSingleActivator(LogicalKeyboardKey.keyN, control: true):
      NextFocusIntent(),
  AdaptiveSingleActivator(LogicalKeyboardKey.keyP, control: true):
      PreviousFocusIntent(),

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

  AdaptiveSingleActivator(LogicalKeyboardKey.keyH, control: true):
      NavigatePaneIntent(AxisDirection.left),
  AdaptiveSingleActivator(LogicalKeyboardKey.keyL, control: true):
      NavigatePaneIntent(AxisDirection.right),
  AdaptiveSingleActivator(LogicalKeyboardKey.keyJ, control: true):
      NavigatePaneIntent(AxisDirection.down),
  AdaptiveSingleActivator(LogicalKeyboardKey.keyK, control: true):
      NavigatePaneIntent(AxisDirection.up),
  AdaptiveSingleActivator(LogicalKeyboardKey.arrowLeft, control: true):
      NavigatePaneIntent(AxisDirection.left),
  AdaptiveSingleActivator(LogicalKeyboardKey.arrowRight, control: true):
      NavigatePaneIntent(AxisDirection.right),
  AdaptiveSingleActivator(LogicalKeyboardKey.arrowDown, control: true):
      NavigatePaneIntent(AxisDirection.down),
  AdaptiveSingleActivator(LogicalKeyboardKey.arrowUp, control: true):
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

class DeleteIntent extends Intent {
  const DeleteIntent();
}

List<ShortcutActivator> shortcutsFor(Type intent) {
  return typewriterShortcuts.entries
      .where((entry) => entry.value.runtimeType == intent)
      .map((entry) => entry.key)
      .toList();
}

List<ShortcutActivator> shortcutsForIntent<I extends Intent>(
  bool Function(I intent) predicate,
) {
  return typewriterShortcuts.entries
      .where((entry) => entry.value is I && predicate(entry.value as I))
      .map((entry) => entry.key)
      .toList();
}
