import "package:flutter/widgets.dart";

class TimelineMoveIntent extends Intent {
  const TimelineMoveIntent({required this.direction});

  final TraversalDirection direction;
}

class TimelineResizeIntent extends Intent {
  const TimelineResizeIntent({required this.direction});

  final TraversalDirection direction;
}

class TimelineCommitIntent extends Intent {
  const TimelineCommitIntent();
}

class TimelineCenterFocusedIntent extends Intent {
  const TimelineCenterFocusedIntent();
}
