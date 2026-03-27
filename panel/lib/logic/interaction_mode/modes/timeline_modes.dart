import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:typewriter_panel/logic/interaction_mode/interaction_mode.dart";
import "package:typewriter_panel/logic/interaction_mode/mode_display.dart";
import "package:typewriter_panel/logic/interaction_mode/mode_shortcut.dart";
import "package:typewriter_panel/logic/interaction_mode/modes/normal_mode.dart";
import "package:typewriter_panel/utils/shortuct.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/action_shortcuts.dart";
import "package:typewriter_panel/widgets/app/components/interaction_mode/mode_display_chip.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_controller.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_intents.dart";

/// Timeline manipulation modde for moving cues.
///
/// This mode provides keyboard shortcuts for moving selected timeline cues
/// using hjkl and arrow keys.
class TimelineMoveMode extends InteractionMode with ModeDisplay, ModeShortcut {
  const TimelineMoveMode();

  @override
  String get name => "Timeline Move";

  @override
  Widget buildDisplay(BuildContext context) {
    return const ModeDisplayChip(label: "Move", color: Colors.deepPurple);
  }

  @override
  List<ActionShortcut> getShortcuts() {
    final movementShortcuts = {
      [LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.keyK]:
          TraversalDirection.up,
      [LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.keyJ]:
          TraversalDirection.down,
      [LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyH]:
          TraversalDirection.left,
      [LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyL]:
          TraversalDirection.right,
    };

    return [
      for (final MapEntry(key: keys, value: direction)
          in movementShortcuts.entries)
        for (final key in keys)
          ActionShortcut(
            id: "timeline_move_${key.debugName?.snakeCase}",
            label: "Move Cue ${direction.name.titleCase()}",
            description: "Move selected cue ${direction.name.toLowerCase()}",
            activators: [
              SingleActivator(key),
              SingleActivator(key, shift: true),
            ],
            priority: 20,
            show: false,
            onInvoke: (ref) => _invokeTimelineMoveIntent(direction),
          ),
      ActionShortcut(
        id: "timeline_move",
        label: "Move",
        description: "Move the selected cues",
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
        ],
        priority: 20,
      ),
      escapeToNormalAction(onInvoke: (_) => _invokeTimelineCommitIntent()),
    ];
  }

  /// Invokes a TimelineMoveIntent to move the currently selected timeline cue.
  ///
  /// This method uses the Flutter Actions system to dispatch a TimelineMoveIntent
  /// that can be handled by the timeline widget or its parent components.
  ///
  /// Parameters:
  /// - [deltaX]: The horizontal movement amount in pixels
  /// - [deltaY]: The vertical movement amount in pixels
  void _invokeTimelineMoveIntent(TraversalDirection direction) {
    final currentFocus = FocusManager.instance.primaryFocus;
    if (currentFocus?.context == null) {
      return;
    }
    Actions.invoke(
      currentFocus!.context!,
      TimelineMoveIntent(direction: direction),
    );
  }
}

/// Timeline manipulation mode for resizing segments.
///
/// This mode provides keyboard shortcuts for resizing selected timeline segments
/// using hjkl and arrow keys.
class TimelineResizeMode extends InteractionMode
    with ModeDisplay, ModeShortcut {
  const TimelineResizeMode({required this.mode});
  final TimelineInteractionMode mode;

  @override
  String get name => "Timeline Resize";

  @override
  Widget buildDisplay(BuildContext context) {
    return const ModeDisplayChip(
      label: "Resize",
      color: Colors.deepOrangeAccent,
    );
  }

  @override
  List<ActionShortcut> getShortcuts() {
    final movementShortcuts = {
      [LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.keyK]:
          TraversalDirection.up,
      [LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.keyJ]:
          TraversalDirection.down,
      [LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyH]:
          TraversalDirection.left,
      [LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyL]:
          TraversalDirection.right,
    };

    return [
      for (final MapEntry(key: keys, value: direction)
          in movementShortcuts.entries)
        for (final key in keys)
          ActionShortcut(
            id: "timeline_resize_${key.debugName?.snakeCase}",
            label: "Resize Segment ${direction.name.titleCase()}",
            description:
                "Resize selected segment ${direction.name.toLowerCase()}",
            activators: [
              SingleActivator(key),
              SingleActivator(key, shift: true),
            ],
            priority: 0,
            show: false,
            onInvoke: (ref) => _invokeTimelineResizeIntent(direction),
          ),
      ActionShortcut(
        id: "timeline_resize",
        label: "Resize",
        description: "Resize the selected segments",
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
        ],
        priority: -1,
      ),
      escapeToNormalAction(onInvoke: (_) => _invokeTimelineCommitIntent()),
    ];
  }

  /// Invokes a TimelineResizeIntent to resize the currently selected timeline segment.
  ///
  /// This method uses the Flutter Actions system to dispatch a TimelineResizeIntent
  /// that can be handled by the timeline widget or its parent components.
  ///
  /// Parameters:
  /// - [deltaX]: The horizontal movement amount in pixels
  /// - [deltaY]: The vertical movement amount in pixels
  void _invokeTimelineResizeIntent(TraversalDirection direction) {
    final currentFocus = FocusManager.instance.primaryFocus;
    if (currentFocus?.context == null) {
      return;
    }
    Actions.invoke(
      currentFocus!.context!,
      TimelineResizeIntent(direction: direction),
    );
  }
}

/// Invokes a TimelineCommitIntent to commit the current timeline changes.
///
/// This method uses the Flutter Actions system to dispatch a TimelineCommitIntent
/// that can be handled by the timeline widget or its parent components.
///
/// Parameters:
/// - [ref]: A [WidgetRef] giving access to providers needed to evaluate
///   current selection state or perform the operation when invoked.
void _invokeTimelineCommitIntent() {
  final currentFocus = FocusManager.instance.primaryFocus;
  if (currentFocus?.context == null) {
    return;
  }
  Actions.invoke(currentFocus!.context!, TimelineCommitIntent());
}
