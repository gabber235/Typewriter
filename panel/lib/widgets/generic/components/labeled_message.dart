import "dart:math";

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_animate/flutter_animate.dart";

class LabeledMessage extends StatelessWidget {
  const LabeledMessage({
    this.label,
    this.message,
    this.labelStyle,
    this.messageStyle,
    super.key,
  });

  final String? label;
  final String? message;
  final TextStyle? labelStyle;
  final TextStyle? messageStyle;

  @override
  Widget build(BuildContext context) {
    final textStyle = DefaultTextStyle.of(context).style;
    final theme = Theme.of(context);
    final hasLabel = label != null && label!.isNotEmpty;
    final hasMessage = message != null && message!.isNotEmpty;
    if (!hasLabel && !hasMessage) return const SizedBox.shrink();

    final textColor = textStyle.color;

    return AnimatedSize(
      alignment: Alignment.topLeft,
      duration: 200.ms,
      child: _LabeledMessageRender(
        label: hasLabel
            ? Text(
                label!,
                style:
                    labelStyle ??
                    theme.textTheme.titleSmall?.copyWith(color: textColor),
              )
            : null,
        message: hasMessage
            ? Text(
                message!,
                style:
                    messageStyle ??
                    theme.textTheme.bodySmall?.copyWith(
                      color: textColor?.withValues(alpha: 0.7),
                    ),
              )
            : null,
      ),
    );
  }
}

enum _LabelSlot { label, message }

class _LabeledMessageRender
    extends SlottedMultiChildRenderObjectWidget<_LabelSlot, RenderBox> {
  const _LabeledMessageRender({this.label, this.message});
  final Widget? label;
  final Widget? message;

  @override
  Widget? childForSlot(_LabelSlot slot) {
    return switch (slot) {
      _LabelSlot.label => label,
      _LabelSlot.message => message,
    };
  }

  @override
  SlottedContainerRenderObjectMixin<_LabelSlot, RenderBox> createRenderObject(
    BuildContext context,
  ) {
    return _RenderLabeledMessage();
  }

  @override
  Iterable<_LabelSlot> get slots => _LabelSlot.values;
}

class _RenderLabeledMessage extends RenderBox
    with SlottedContainerRenderObjectMixin<_LabelSlot, RenderBox> {
  RenderBox? get _label => childForSlot(_LabelSlot.label);
  RenderBox? get _message => childForSlot(_LabelSlot.message);

  @override
  Iterable<RenderBox> get children => [?_label, ?_message];

  int _laidOutChildren = 0;

  @override
  void performLayout() {
    final childConstraint = BoxConstraints(maxWidth: constraints.maxWidth);

    _label?.layout(childConstraint, parentUsesSize: true);
    _message?.layout(childConstraint, parentUsesSize: true);

    var height = 0.0;
    final maxHeight = constraints.maxHeight;
    var maxWidth = 0.0;
    _laidOutChildren = 0;
    for (final child in children) {
      final size = child.size;
      if (size.height + height > maxHeight) {
        break;
      }
      _laidOutChildren++;
      _positionChild(child, Offset(0, height));
      height += size.height;
      maxWidth = max(maxWidth, size.width);
    }
    size = constraints.constrain(Size(maxWidth, height));
  }

  void _positionChild(RenderBox child, Offset offset) {
    (child.parentData! as BoxParentData).offset = offset;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    void paintChild(RenderBox child, PaintingContext context, Offset offset) {
      final childParentData = child.parentData! as BoxParentData;
      context.paintChild(child, childParentData.offset + offset);
    }

    for (final child in children.take(_laidOutChildren)) {
      paintChild(child, context, offset);
    }
  }

  // HIT TEST

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in children) {
      final parentData = child.parentData! as BoxParentData;
      final isHit = result.addWithPaintOffset(
        offset: parentData.offset,
        position: position,
        hitTest: (result, transformed) {
          assert(transformed == position - parentData.offset);
          return child.hitTest(result, position: transformed);
        },
      );
      if (isHit) {
        return true;
      }
    }
    return false;
  }

  // INTRINSICS

  // Incoming height/width are ignored as children are always laid out unconstrained.

  @override
  double computeMinIntrinsicWidth(double height) {
    final labelWidth = _label?.getMinIntrinsicWidth(double.infinity) ?? 0;
    final messageWidth = _message?.getMinIntrinsicWidth(double.infinity) ?? 0;
    return max(labelWidth, messageWidth);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final labelWidth = _label?.getMaxIntrinsicWidth(double.infinity) ?? 0;
    final messageWidth = _message?.getMaxIntrinsicWidth(double.infinity) ?? 0;
    return max(labelWidth, messageWidth);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final labelHeight = _label?.getMinIntrinsicHeight(width) ?? 0;
    final messageHeight = _message?.getMinIntrinsicHeight(width) ?? 0;
    return labelHeight + messageHeight;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final labelHeight = _label?.getMaxIntrinsicHeight(width) ?? 0;
    final messageHeight = _message?.getMaxIntrinsicHeight(width) ?? 0;
    return labelHeight + messageHeight;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final childConstraints = BoxConstraints(maxWidth: constraints.maxWidth);
    final labelSize = _label?.getDryLayout(childConstraints) ?? Size.zero;
    final messageSize = _message?.getDryLayout(childConstraints) ?? Size.zero;
    return constraints.constrain(
      Size(
        max(labelSize.width, messageSize.width),
        labelSize.height + messageSize.height,
      ),
    );
  }
}
