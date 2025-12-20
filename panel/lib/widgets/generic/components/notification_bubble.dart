import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_animate/flutter_animate.dart";

/// Corners available for anchoring the bubble.
enum NotificationBubbleAnchor { topLeft, topRight, bottomLeft, bottomRight }

enum NotificationSlot { child, bubble }

class NotificationBubble
    extends SlottedMultiChildRenderObjectWidget<NotificationSlot, RenderBox> {
  const NotificationBubble({
    required this.child,
    required this.bubbleBuilder,
    this.anchor = NotificationBubbleAnchor.topRight,
    this.overlap = 6.0,
    this.show = true,
    this.semanticsLabel,
    super.key,
  });

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
    return NotificationBubble(
      overlap: overlap,
      semanticsLabel: semanticsLabel,
      show: show,
      key: key,
      bubbleBuilder: (context) {
        final theme = Theme.of(context);
        final c = color ?? theme.colorScheme.error;

        return Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        );
      },
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
    final effectiveShow = !(hideWhenZero && count == 0) && show;
    return NotificationBubble(
      bubbleBuilder: (context) {
        final theme = Theme.of(context);
        final color = backgroundColor ?? theme.colorScheme.error;
        final onColor = foregroundColor ?? theme.colorScheme.onError;
        final text = count > maxCount ? "$maxCount+" : count.toString();

        return Container(
          clipBehavior: Clip.none,
          decoration: ShapeDecoration(
            color: color,
            shape: text.length > 2
                ? const StadiumBorder()
                : const CircleBorder(),
          ),
          padding: EdgeInsets.all(6),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: onColor,
              fontSize: 10,
              fontVariations: const [FontVariation("wght", 700)],
              letterSpacing: 0.7,
            ),
          ),
        );
      },
      anchor: anchor,
      overlap: overlap,
      semanticsLabel: semanticsLabel,
      show: effectiveShow,
      key: key,
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
    return NotificationBubble(
      bubbleBuilder: (_) => bubble,
      anchor: anchor,
      overlap: overlap,
      semanticsLabel: semanticsLabel,
      show: show,
      key: key,
      child: child,
    );
  }

  final Widget child;
  final WidgetBuilder bubbleBuilder;
  final NotificationBubbleAnchor anchor;
  final double overlap;
  final bool show;
  final String? semanticsLabel;

  @override
  Iterable<NotificationSlot> get slots => NotificationSlot.values;

  @override
  Widget? childForSlot(NotificationSlot slot) {
    switch (slot) {
      case NotificationSlot.child:
        return child;
      case NotificationSlot.bubble:
        return Builder(
          builder: (context) {
            return Semantics(
                  label: semanticsLabel,
                  child: bubbleBuilder(context),
                )
                .animate(target: show ? 1.0 : 0.0)
                .scaleXY(begin: 0.7, end: 1.0)
                .fade(
                  duration: 200.ms,
                  delay: show ? 0.ms : 550.ms,
                  curve: Curves.easeInOut,
                );
          },
        );
    }
  }

  @override
  SlottedContainerRenderObjectMixin<NotificationSlot, RenderBox>
  createRenderObject(BuildContext context) {
    return NotificationBubbleRenderBox(anchor: anchor, overlap: overlap);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    NotificationBubbleRenderBox renderObject,
  ) {
    renderObject
      ..anchor = anchor
      ..overlap = overlap;
  }
}

class NotificationBubbleRenderBox extends RenderBox
    with SlottedContainerRenderObjectMixin<NotificationSlot, RenderBox> {
  NotificationBubbleRenderBox({
    required NotificationBubbleAnchor anchor,
    required double overlap,
  }) : _anchor = anchor,
       _overlap = overlap;

  NotificationBubbleAnchor _anchor;
  NotificationBubbleAnchor get anchor => _anchor;
  set anchor(NotificationBubbleAnchor value) {
    if (anchor == value) return;
    _anchor = value;
    markNeedsLayout();
  }

  double _overlap;
  double get overlap => _overlap;
  set overlap(double value) {
    if (overlap == value) return;
    _overlap = value;
    markNeedsLayout();
  }

  RenderBox? _child;
  RenderBox? _bubble;

  @override
  void performLayout() {
    _child = childForSlot(NotificationSlot.child);
    _bubble = childForSlot(NotificationSlot.bubble);

    if (_child == null) {
      size = Size.zero;
      return;
    }

    _child!.layout(constraints, parentUsesSize: true);
    size = _child!.size;

    if (_bubble == null) return;
    _bubble!.layout(BoxConstraints(), parentUsesSize: true);
    final alignment = _alignmentFor(anchor);
    final slide = _offsetFor(anchor, overlap);

    final offset = alignment.alongSize(size);

    final bubbleSize = _bubble!.size;
    final bubbleAlignment = Alignment(-alignment.x, -alignment.y);
    final bubbleOffset = bubbleAlignment.alongSize(bubbleSize);

    (_bubble!.parentData! as BoxParentData).offset =
        offset - bubbleOffset - slide;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_child == null) return;
    context.paintChild(_child!, offset);

    if (_bubble == null) return;
    final bubbleOffset = (_bubble!.parentData! as BoxParentData).offset;
    context.paintChild(_bubble!, offset + bubbleOffset);
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
}
