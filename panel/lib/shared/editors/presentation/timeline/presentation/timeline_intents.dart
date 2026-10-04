import "package:flutter/widgets.dart";

/// Requests one frame movement step for the active timeline edit mode.
class TimelineMoveIntent extends Intent {
  const TimelineMoveIntent({required this.direction});

  final TraversalDirection direction;
}

/// Requests one frame resize step for the active segment edge.
class TimelineResizeIntent extends Intent {
  const TimelineResizeIntent({required this.direction});

  final TraversalDirection direction;
}

/// Requests the enclosing timeline to finish and delegate the current draft.
class TimelineCommitIntent extends Intent {
  const TimelineCommitIntent();
}

/// Requests viewport centering on the primary focused element.
class TimelineCenterFocusedIntent extends Intent {
  const TimelineCenterFocusedIntent();
}
