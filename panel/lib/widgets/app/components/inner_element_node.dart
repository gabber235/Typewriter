// ignore_for_file: library_private_types_in_public_api

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:typewriter_panel/logic/pages/element_blueprint.dart";
import "package:typewriter_panel/widgets/generic/components/icones.dart";

class InnerElementNode extends StatelessWidget {
  const InnerElementNode({
    required this.name,
    required this.blueprint,
    required this.color,
    required this.isDeprecated,
    this.isReference = false,
    this.pageId,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.compactPadding = const EdgeInsets.all(4),
    this.iconSize = 18,
    this.fontSize = 13,
    this.secondaryFontSize = 11,
    super.key,
  });

  final String name;
  final ElementBlueprint blueprint;
  final Color color;
  final bool isDeprecated;
  final bool isReference;
  final String? pageId;
  final EdgeInsets padding;
  final EdgeInsets compactPadding;
  final double iconSize;
  final double fontSize;
  final double secondaryFontSize;

  @override
  Widget build(BuildContext context) {
    final centerContent = isReference && pageId != null
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  name,
                  style: TextStyle(
                    color: color,
                    fontSize: fontSize,
                    decoration: isDeprecated
                        ? TextDecoration.lineThrough
                        : null,
                    decorationThickness: 2.8,
                    decorationColor: color,
                    decorationStyle: TextDecorationStyle.wavy,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                "Page: $pageId",
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: secondaryFontSize,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          )
        : Text(
            name,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              decoration: isDeprecated ? TextDecoration.lineThrough : null,
              decorationThickness: 2.8,
              decorationColor: color,
              decorationStyle: TextDecorationStyle.wavy,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          );

    return AdaptiveElementLayout(
      padding: padding,
      compactPadding: compactPadding,
      leading: Icones(blueprint.icon, size: iconSize, color: color),
      center: centerContent,
      suffix: isReference
          ? Icon(Icons.open_in_new, color: color, size: iconSize)
          : null,
    );
  }
}

enum _ElementSlot { leading, center, suffix }

class AdaptiveElementLayout
    extends SlottedMultiChildRenderObjectWidget<_ElementSlot, RenderBox> {
  const AdaptiveElementLayout({
    required this.leading,
    this.center,
    this.suffix,
    this.padding = EdgeInsets.zero,
    this.compactPadding,
    // ignore: unused_element_parameter
    this.minCenterWidth = 30.0,
    super.key,
  });

  final Widget leading;
  final Widget? center;
  final Widget? suffix;
  final EdgeInsets padding;
  final EdgeInsets? compactPadding;
  final double minCenterWidth;

  @override
  Iterable<_ElementSlot> get slots => _ElementSlot.values;

  @override
  Widget? childForSlot(_ElementSlot slot) {
    return switch (slot) {
      _ElementSlot.leading => leading,
      _ElementSlot.center => center,
      _ElementSlot.suffix => suffix,
    };
  }

  @override
  SlottedContainerRenderObjectMixin<_ElementSlot, RenderBox> createRenderObject(
    BuildContext context,
  ) {
    return _RenderAdaptiveElementLayout(
      padding: padding,
      compactPadding: compactPadding ?? padding,
      minCenterWidth: minCenterWidth,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderAdaptiveElementLayout renderObject,
  ) {
    renderObject
      ..padding = padding
      ..compactPadding = compactPadding ?? padding
      ..minCenterWidth = minCenterWidth;
  }
}

class _RenderAdaptiveElementLayout extends RenderBox
    with SlottedContainerRenderObjectMixin<_ElementSlot, RenderBox> {
  _RenderAdaptiveElementLayout({
    required EdgeInsets padding,
    required EdgeInsets compactPadding,
    required double minCenterWidth,
  }) : _padding = padding,
       _compactPadding = compactPadding,
       _minCenterWidth = minCenterWidth;

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

  static const double _spacing = 8.0;

  bool _showCenter = false;
  bool _showSuffix = false;

  @override
  void performLayout() {
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
        (centerChild != null ? _spacing + _minCenterWidth : 0) +
        (suffixChild != null ? _spacing + suffixSize.width : 0);

    final minWidthForLeadingCenter =
        _padding.horizontal +
        leadingSize.width +
        (centerChild != null ? _spacing + _minCenterWidth : 0);

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

    size = constraints.constrain(Size(availableWidth, constraints.maxHeight));

    final contentWidth = size.width - activePadding.horizontal;
    final verticalCenter = size.height / 2;

    if (_showCenter && _showSuffix) {
      final leadingX = activePadding.left;
      final suffixX = size.width - activePadding.right - suffixSize.width;
      final centerStartX = leadingX + leadingSize.width + _spacing;
      final centerEndX = suffixX - _spacing;
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
      final centerX =
          centerStartX + (centerAvailableWidth - actualCenterWidth) / 2;

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
      final centerStartX = leadingX + leadingSize.width + _spacing;
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
      final centerX =
          centerStartX + (centerAvailableWidth - actualCenterWidth) / 2;

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
}
