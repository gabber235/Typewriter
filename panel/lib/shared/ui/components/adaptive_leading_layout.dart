// ignore_for_file: library_private_types_in_public_api

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";

enum _ElementSlot { leading, center, suffix }

/// Lays out a leading control, optional centered content, and optional suffix.
///
/// The center and suffix are progressively omitted when the incoming width
/// cannot preserve the configured minimum center width. The render object owns
/// that responsive decision, so callers do not need separate breakpoint trees.
class AdaptiveLeadingLayout
    extends SlottedMultiChildRenderObjectWidget<_ElementSlot, RenderBox> {
  const AdaptiveLeadingLayout({
    required this.leading,
    this.center,
    this.suffix,
    this.padding = EdgeInsets.zero,
    this.compactPadding,
    this.minCenterWidth = 30.0,
    this.gap = 8.0,
    super.key,
  }) : assert(minCenterWidth >= 0 && minCenterWidth != double.infinity),
       assert(gap >= 0 && gap != double.infinity);

  final Widget leading;
  final Widget? center;
  final Widget? suffix;
  final EdgeInsets padding;
  final EdgeInsets? compactPadding;
  final double minCenterWidth;
  final double gap;

  @override
  Iterable<_ElementSlot> get slots => _ElementSlot.values;

  @override
  Widget? childForSlot(_ElementSlot slot) {
    return switch (slot) {
      _ElementSlot.leading => _AdaptiveSlot(visible: true, child: leading),
      _ElementSlot.center =>
        center == null ? null : _AdaptiveSlot(visible: false, child: center!),
      _ElementSlot.suffix =>
        suffix == null ? null : _AdaptiveSlot(visible: false, child: suffix!),
    };
  }

  @override
  SlottedContainerRenderObjectMixin<_ElementSlot, RenderBox> createRenderObject(
    BuildContext context,
  ) {
    return _RenderAdaptiveLeadingLayout(
      padding: padding,
      compactPadding: compactPadding ?? padding,
      minCenterWidth: minCenterWidth,
      gap: gap,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderAdaptiveLeadingLayout renderObject,
  ) {
    renderObject
      ..padding = padding
      ..compactPadding = compactPadding ?? padding
      ..minCenterWidth = minCenterWidth
      ..gap = gap;
  }
}

class _RenderAdaptiveLeadingLayout extends RenderBox
    with SlottedContainerRenderObjectMixin<_ElementSlot, RenderBox> {
  _RenderAdaptiveLeadingLayout({
    required this._padding,
    required this._compactPadding,
    required this._minCenterWidth,
    required this._gap,
  });

  EdgeInsets _padding;
  EdgeInsets get padding => _padding;
  set padding(EdgeInsets value) {
    if (_padding == value) return;
    _padding = value;
    markNeedsLayout();
  }

  EdgeInsets _compactPadding;
  EdgeInsets get compactPadding => _compactPadding;
  set compactPadding(EdgeInsets value) {
    if (_compactPadding == value) return;
    _compactPadding = value;
    markNeedsLayout();
  }

  double _minCenterWidth;
  double get minCenterWidth => _minCenterWidth;
  set minCenterWidth(double value) {
    if (_minCenterWidth == value) return;
    _minCenterWidth = value;
    markNeedsLayout();
  }

  double _gap;
  double get gap => _gap;
  set gap(double value) {
    if (_gap == value) return;
    _gap = value;
    markNeedsLayout();
  }

  bool _showCenter = false;
  bool _showSuffix = false;

  @override
  void performLayout() {
    if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
      final zero = BoxConstraints.tight(Size.zero);
      for (final slot in _ElementSlot.values) {
        childForSlot(slot)?.layout(zero);
      }
      size = constraints.constrain(Size.zero);
      throw FlutterError(
        "AdaptiveLeadingLayout requires finite maximum width and height.",
      );
    }
    final leadingChild = childForSlot(_ElementSlot.leading);
    final centerChild = childForSlot(_ElementSlot.center);
    final suffixChild = childForSlot(_ElementSlot.suffix);

    final looseConstraints = BoxConstraints.loose(
      Size(constraints.maxWidth, constraints.maxHeight),
    );

    final leadingSize = leadingChild != null
        ? (leadingChild..layout(looseConstraints, parentUsesSize: true)).size
        : Size.zero;

    final centerSize = centerChild != null
        ? (centerChild..layout(looseConstraints, parentUsesSize: true)).size
        : Size.zero;

    final suffixSize = suffixChild != null
        ? (suffixChild..layout(looseConstraints, parentUsesSize: true)).size
        : Size.zero;

    final availableWidth = constraints.maxWidth;

    final minWidthForAllThree =
        _padding.horizontal +
        leadingSize.width +
        (centerChild != null ? _gap + _minCenterWidth : 0) +
        (suffixChild != null ? _gap + suffixSize.width : 0);

    final minWidthForLeadingCenter =
        _padding.horizontal +
        leadingSize.width +
        (centerChild != null ? _gap + _minCenterWidth : 0);

    final previousShowCenter = _showCenter;
    final previousShowSuffix = _showSuffix;
    _showCenter = false;
    _showSuffix = false;
    EdgeInsets activePadding;

    if (suffixChild != null &&
        centerChild != null &&
        minWidthForAllThree <= availableWidth) {
      _showCenter = true;
      _showSuffix = true;
      activePadding = _padding;
    } else if (centerChild != null &&
        minWidthForLeadingCenter <= availableWidth) {
      _showCenter = true;
      activePadding = _padding;
    } else {
      activePadding = _compactPadding;
    }

    (leadingChild as _RenderAdaptiveSlot?)?.visible = true;
    (centerChild as _RenderAdaptiveSlot?)?.visible = _showCenter;
    (suffixChild as _RenderAdaptiveSlot?)?.visible = _showSuffix;
    if (previousShowCenter != _showCenter ||
        previousShowSuffix != _showSuffix) {
      markNeedsSemanticsUpdate();
    }

    size = constraints.constrain(Size(availableWidth, constraints.maxHeight));

    final contentWidth = size.width - activePadding.horizontal;
    final verticalCenter = size.height / 2;

    if (_showCenter && _showSuffix) {
      final leadingX = activePadding.left;
      final suffixX = size.width - activePadding.right - suffixSize.width;
      final centerStartX = leadingX + leadingSize.width + _gap;
      final centerEndX = suffixX - _gap;
      final centerAvailableWidth = centerEndX - centerStartX;

      if (centerChild != null) {
        if (centerAvailableWidth < centerSize.width) {
          centerChild.layout(
            BoxConstraints(
              maxWidth: centerAvailableWidth,
              maxHeight: constraints.maxHeight,
            ),
            parentUsesSize: true,
          );
        }
      }

      final actualCenterWidth = centerChild?.size.width ?? 0;
      final centerX = _centerXWithinBounds(
        centerWidth: actualCenterWidth,
        startX: centerStartX,
        endX: centerEndX,
      );

      if (leadingChild != null) {
        (leadingChild.parentData! as BoxParentData).offset = Offset(
          leadingX,
          verticalCenter - leadingSize.height / 2,
        );
      }

      if (centerChild != null) {
        (centerChild.parentData! as BoxParentData).offset = Offset(
          centerX,
          verticalCenter - centerChild.size.height / 2,
        );
      }

      if (suffixChild != null) {
        (suffixChild.parentData! as BoxParentData).offset = Offset(
          suffixX,
          verticalCenter - suffixSize.height / 2,
        );
      }
    } else if (_showCenter) {
      final leadingX = activePadding.left;
      final centerStartX = leadingX + leadingSize.width + _gap;
      final centerEndX = size.width - activePadding.right;
      final centerAvailableWidth = centerEndX - centerStartX;

      if (centerChild != null) {
        if (centerAvailableWidth < centerSize.width) {
          centerChild.layout(
            BoxConstraints(
              maxWidth: centerAvailableWidth,
              maxHeight: constraints.maxHeight,
            ),
            parentUsesSize: true,
          );
        }
      }

      final actualCenterWidth = centerChild?.size.width ?? 0;
      final centerX = _centerXWithinBounds(
        centerWidth: actualCenterWidth,
        startX: centerStartX,
        endX: centerEndX,
      );

      if (leadingChild != null) {
        (leadingChild.parentData! as BoxParentData).offset = Offset(
          leadingX,
          verticalCenter - leadingSize.height / 2,
        );
      }

      if (centerChild != null) {
        (centerChild.parentData! as BoxParentData).offset = Offset(
          centerX,
          verticalCenter - centerChild.size.height / 2,
        );
      }
    } else {
      final leadingX =
          activePadding.left + (contentWidth - leadingSize.width) / 2;

      if (leadingChild != null) {
        (leadingChild.parentData! as BoxParentData).offset = Offset(
          leadingX,
          verticalCenter - leadingSize.height / 2,
        );
      }
    }
  }

  double _centerXWithinBounds({
    required double centerWidth,
    required double startX,
    required double endX,
  }) {
    final centeredX = (size.width - centerWidth) / 2;
    return centeredX.clamp(startX, endX - centerWidth);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final leadingChild = childForSlot(_ElementSlot.leading);
    final centerChild = childForSlot(_ElementSlot.center);
    final suffixChild = childForSlot(_ElementSlot.suffix);

    if (leadingChild != null) {
      final childParentData = leadingChild.parentData! as BoxParentData;
      context.paintChild(leadingChild, childParentData.offset + offset);
    }

    if (_showCenter && centerChild != null) {
      final childParentData = centerChild.parentData! as BoxParentData;
      context.paintChild(centerChild, childParentData.offset + offset);
    }

    if (_showSuffix && suffixChild != null) {
      final childParentData = suffixChild.parentData! as BoxParentData;
      context.paintChild(suffixChild, childParentData.offset + offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final leadingChild = childForSlot(_ElementSlot.leading);
    final centerChild = childForSlot(_ElementSlot.center);
    final suffixChild = childForSlot(_ElementSlot.suffix);

    for (final child in [
      if (_showSuffix && suffixChild != null) suffixChild,
      if (_showCenter && centerChild != null) centerChild,
      ?leadingChild,
    ]) {
      final childParentData = child.parentData! as BoxParentData;
      final isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (result, transformed) {
          return child.hitTest(result, position: transformed);
        },
      );
      if (isHit) return true;
    }

    return false;
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    final leadingChild = childForSlot(_ElementSlot.leading);
    final centerChild = childForSlot(_ElementSlot.center);
    final suffixChild = childForSlot(_ElementSlot.suffix);
    if (leadingChild != null) visitor(leadingChild);
    if (_showCenter && centerChild != null) visitor(centerChild);
    if (_showSuffix && suffixChild != null) visitor(suffixChild);
  }
}

class _AdaptiveSlot extends StatefulWidget {
  const _AdaptiveSlot({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  State<_AdaptiveSlot> createState() => _AdaptiveSlotState();
}

class _AdaptiveSlotState extends State<_AdaptiveSlot> {
  late bool _visible = widget.visible;
  final FocusNode _focusNode = FocusNode(
    debugLabel: "AdaptiveLeadingLayout slot",
  );

  void _setVisible(bool value) {
    if (!mounted || _visible == value) return;
    if (!value && _focusNode.hasFocus) _focusNode.unfocus();
    setState(() => _visible = value);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AdaptiveSlotRenderWidget(
      visible: widget.visible,
      onVisibilityChanged: _setVisible,
      child: Focus(
        focusNode: _focusNode,
        canRequestFocus: _visible,
        descendantsAreFocusable: _visible,
        child: ExcludeSemantics(excluding: !_visible, child: widget.child),
      ),
    );
  }
}

class _AdaptiveSlotRenderWidget extends SingleChildRenderObjectWidget {
  const _AdaptiveSlotRenderWidget({
    required this.visible,
    required this.onVisibilityChanged,
    required super.child,
  });

  final bool visible;
  final ValueChanged<bool> onVisibilityChanged;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderAdaptiveSlot(visible, onVisibilityChanged);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderAdaptiveSlot renderObject,
  ) {
    renderObject.onVisibilityChanged = onVisibilityChanged;
  }
}

class _RenderAdaptiveSlot extends RenderProxyBox {
  _RenderAdaptiveSlot(this._visible, this.onVisibilityChanged);

  ValueChanged<bool> onVisibilityChanged;

  bool _visible;
  bool _visibilityCallbackScheduled = false;
  bool get visible => _visible;
  set visible(bool value) {
    if (_visible == value) return;
    _visible = value;
    markNeedsSemanticsUpdate();
    if (_visibilityCallbackScheduled) return;
    _visibilityCallbackScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibilityCallbackScheduled = false;
      if (attached) onVisibilityChanged(_visible);
    });
  }
}
