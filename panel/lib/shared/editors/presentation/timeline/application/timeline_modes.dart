import "package:typewriter_panel/typewriter_panel.dart";

/// Timeline manipulation mode for moving cues.
///
/// Directional keyboard shortcuts update the active previews. Escape finishes
/// the session through the timeline's commit action.
class TimelineMoveMode extends InteractionMode
    with ModeDisplay, ModeShortcut, DirectionalInteractionMode {
  const TimelineMoveMode();

  @override
  String get name => "Timeline Move";

  @override
  Widget buildDisplay(BuildContext context) {
    return ModeDisplayChip(label: "Move", color: context.colors.accent);
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

/// Timeline manipulation mode for resizing segment boundaries.
///
/// Directional keyboard shortcuts update the selected edge previews. Escape
/// finishes the session through the timeline's commit action.
class TimelineResizeMode extends InteractionMode
    with ModeDisplay, ModeShortcut, DirectionalInteractionMode {
  const TimelineResizeMode({required this.mode});
  final TimelineInteractionMode mode;

  @override
  String get name => "Timeline Resize";

  @override
  Widget buildDisplay(BuildContext context) {
    return ModeDisplayChip(label: "Resize", color: context.colors.warning);
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

/// Dispatches the commit intent from the currently focused Flutter context.
///
/// If focus has no context, the request is ignored because there is no actions
/// scope that can own the session. The focused timeline supplies the handler.
void _invokeTimelineCommitIntent() {
  final currentFocus = FocusManager.instance.primaryFocus;
  if (currentFocus?.context == null) {
    return;
  }
  Actions.invoke(currentFocus!.context!, TimelineCommitIntent());
}
