import "dart:math" as math;

import "package:flutter/rendering.dart";
import "package:flutter/widgets.dart";

/// Centers its slivers as one block when they are shorter than the available
/// viewport, while retaining normal lazy scrolling when they overflow.
class CenteredSliverMainAxisGroup extends SingleChildRenderObjectWidget {
  CenteredSliverMainAxisGroup({required List<Widget> slivers, super.key})
    : super(child: SliverMainAxisGroup(slivers: slivers));

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderCenteredSliverMainAxisGroup();
  }
}

class _RenderCenteredSliverMainAxisGroup extends RenderSliverEdgeInsetsPadding {
  EdgeInsets _resolvedPadding = EdgeInsets.zero;

  @override
  EdgeInsets get resolvedPadding => _resolvedPadding;

  @override
  void performLayout() {
    _resolvedPadding = EdgeInsets.zero;
    super.performLayout();

    final childGeometry = child!.geometry!;
    if (childGeometry.scrollOffsetCorrection != null) {
      return;
    }

    final fillExtent = math.max(
      0.0,
      constraints.viewportMainAxisExtent - constraints.precedingScrollExtent,
    );
    final paddingExtent =
        math.max(0.0, fillExtent - childGeometry.scrollExtent) / 2;
    final nextPadding = switch (constraints.axis) {
      Axis.vertical => EdgeInsets.symmetric(vertical: paddingExtent),
      Axis.horizontal => EdgeInsets.symmetric(horizontal: paddingExtent),
    };

    if (nextPadding == EdgeInsets.zero) {
      return;
    }

    _resolvedPadding = nextPadding;
    super.performLayout();
  }
}
