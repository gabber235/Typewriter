import "package:typewriter_panel/typewriter_panel.dart";

/// Centers a sliver group when its content is shorter than the viewport.
///
/// Padding is derived during sliver layout, so overflowing content keeps normal
/// scrolling and the child remains a single lazy sliver group.
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

    final fillExtent = max(
      0.0,
      constraints.viewportMainAxisExtent - constraints.precedingScrollExtent,
    );
    final paddingExtent = max(0.0, fillExtent - childGeometry.scrollExtent) / 2;
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
