import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Timeline manipulation modde for moving cues.
///
/// This mode provides keyboard shortcuts for moving selected timeline cues
/// using hjkl and arrow keys.
class TimelineMoveMode extends InteractionMode
    with ModeDisplay, ModeShortcut, DirectionalInteractionMode {
  const TimelineMoveMode();

  @override
  String get name => "Timeline Move";

  @override
  Widget buildDisplay(BuildContext context) {
    return const ModeDisplayChip(label: "Move", color: Colors.deepPurple);
  }

  @override
  List<ActionShortcut> getShortcuts() {
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
            onInvoke: (ref) => invokeCurrentModeDirection(ref, direction),
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

  @override
  Intent intentForDirection(TraversalDirection direction) =>
      TimelineMoveIntent(direction: direction);
}

/// Timeline manipulation mode for resizing segments.
///
/// This mode provides keyboard shortcuts for resizing selected timeline segments
/// using hjkl and arrow keys.
class TimelineResizeMode extends InteractionMode
    with ModeDisplay, ModeShortcut, DirectionalInteractionMode {
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
            onInvoke: (ref) => invokeCurrentModeDirection(ref, direction),
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

  @override
  Intent intentForDirection(TraversalDirection direction) =>
      TimelineResizeIntent(direction: direction);
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
