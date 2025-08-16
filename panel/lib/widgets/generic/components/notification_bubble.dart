import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";

/// Overlays a notification bubble anchored to a child widget.
abstract class NotificationBubble extends StatelessWidget {
  const NotificationBubble({super.key});

  /// Small circular indicator bubble.
  factory NotificationBubble.dot({
    required Widget child,
    NotificationBubbleAnchor anchor = NotificationBubbleAnchor.topRight,
    double overlap = 6,
    double dotSize = 10,
    Color? color,
    String? semanticsLabel,
    bool show = true,
    Key? key,
  }) {
    return _NotificationBubbleDot(
      key: key,
      anchor: anchor,
      overlap: overlap,
      dotSize: dotSize,
      color: color,
      semanticsLabel: semanticsLabel,
      show: show,
      child: child,
    );
  }

  /// Numeric badge with optional capping, e.g., "99+".
  factory NotificationBubble.count({
    required Widget child,
    required int count,
    NotificationBubbleAnchor anchor = NotificationBubbleAnchor.topRight,
    double overlap = 6,
    int maxCount = 99,
    bool hideWhenZero = true,
    Color? backgroundColor,
    Color? foregroundColor,
    String? semanticsLabel,
    bool show = true,
    Key? key,
  }) {
    return _NotificationBubbleCount(
      key: key,
      count: count,
      anchor: anchor,
      overlap: overlap,
      maxCount: maxCount,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      semanticsLabel: semanticsLabel,
      show: !(hideWhenZero && count == 0) && show,
      child: child,
    );
  }

  /// Fully custom bubble content.
  factory NotificationBubble.custom({
    required Widget child,
    required Widget bubble,
    NotificationBubbleAnchor anchor = NotificationBubbleAnchor.topRight,
    double overlap = 6,
    String? semanticsLabel,
    bool show = true,
    Key? key,
  }) {
    return _NotificationBubbleCustom(
      key: key,
      bubble: bubble,
      anchor: anchor,
      overlap: overlap,
      semanticsLabel: semanticsLabel,
      show: show,
      child: child,
    );
  }
}

/// Corners available for anchoring the bubble.
enum NotificationBubbleAnchor {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

abstract class _NotificationBubbleBase extends NotificationBubble {
  const _NotificationBubbleBase({
    required this.child,
    required this.anchor,
    required this.overlap,
    required this.show,
    this.semanticsLabel,
    super.key,
  });

  final Widget child;
  final NotificationBubbleAnchor anchor;
  final double overlap;
  final bool show;
  final String? semanticsLabel;

  @protected
  Widget buildBubble(BuildContext context);

  @override
  Widget build(BuildContext context) {
    final bubble = buildBubble(context);
    final offset = _offsetFor(anchor, overlap);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned.fill(
          child: Align(
            alignment: _alignmentFor(anchor),
            child: Semantics(
              label: semanticsLabel,
              child: bubble,
            )
                .animate(target: show ? 1.0 : 0.0)
                .move(
                  curve: show ? ElasticOutCurve(0.5) : Curves.easeIn,
                  duration: 750.ms,
                  begin: show ? offset / 2 : offset,
                  end: offset,
                )
                .scaleXY(
                  begin: 0.7,
                  end: 1.0,
                )
                .fade(
                  duration: 200.ms,
                  delay: show ? 0.ms : 550.ms,
                  curve: Curves.easeInOut,
                ),
          ),
        ),
      ],
    );
  }
}

class _NotificationBubbleDot extends _NotificationBubbleBase {
  const _NotificationBubbleDot({
    required super.child,
    required super.anchor,
    required super.overlap,
    required this.dotSize,
    required this.color,
    required super.semanticsLabel,
    required super.show,
    super.key,
  });

  final double dotSize;
  final Color? color;

  @override
  Widget buildBubble(BuildContext context) {
    final theme = Theme.of(context);
    final color = this.color ?? theme.colorScheme.error;

    return Container(
      width: dotSize,
      height: dotSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _NotificationBubbleCount extends _NotificationBubbleBase {
  const _NotificationBubbleCount({
    required super.child,
    required super.anchor,
    required super.overlap,
    required this.count,
    required this.maxCount,
    required this.backgroundColor,
    required this.foregroundColor,
    required super.semanticsLabel,
    required super.show,
    super.key,
  });

  final int count;
  final int maxCount;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget buildBubble(BuildContext context) {
    final theme = Theme.of(context);
    final color = backgroundColor ?? theme.colorScheme.error;
    final onColor = foregroundColor ?? theme.colorScheme.onError;

    final text = count > maxCount ? "$maxCount+" : count.toString();

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: 24,
        minHeight: 24,
      ),
      child: Container(
        clipBehavior: Clip.none,
        decoration: ShapeDecoration(
          color: color,
          shape: StadiumBorder(),
        ),
        padding: EdgeInsets.all(4),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: onColor,
            fontSize: 10,
            fontVariations: [FontVariation("wght", 700)],
            letterSpacing: 0.7,
          ),
        ),
      ),
    );
  }
}

class _NotificationBubbleCustom extends _NotificationBubbleBase {
  const _NotificationBubbleCustom({
    required super.child,
    required super.anchor,
    required super.overlap,
    required this.bubble,
    required super.semanticsLabel,
    required super.show,
    super.key,
  });

  final Widget bubble;

  @override
  Widget buildBubble(BuildContext context) => bubble;
}

Alignment _alignmentFor(NotificationBubbleAnchor anchor) {
  switch (anchor) {
    case NotificationBubbleAnchor.topLeft:
      return Alignment.topLeft;
    case NotificationBubbleAnchor.topRight:
      return Alignment.topRight;
    case NotificationBubbleAnchor.bottomLeft:
      return Alignment.bottomLeft;
    case NotificationBubbleAnchor.bottomRight:
      return Alignment.bottomRight;
  }
}

Offset _offsetFor(NotificationBubbleAnchor anchor, double overlap) {
  switch (anchor) {
    case NotificationBubbleAnchor.topLeft:
      return Offset(-overlap, -overlap);
    case NotificationBubbleAnchor.topRight:
      return Offset(overlap, -overlap);
    case NotificationBubbleAnchor.bottomLeft:
      return Offset(-overlap, overlap);
    case NotificationBubbleAnchor.bottomRight:
      return Offset(overlap, overlap);
  }
}
