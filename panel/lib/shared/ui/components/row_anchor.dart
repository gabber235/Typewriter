import "package:typewriter_panel/typewriter_panel.dart";

/// Keeps on screen rows still when rows above the leading edge change, the
/// way CSS scroll anchoring does: it anchors on the first row on screen and
/// turns any move of that row that no scroll caused into a scroll offset
/// correction. Rows the list has not built count too, since they move the
/// anchor row just the same. At scroll offset 0 nothing is anchored, so a
/// row added at the top is seen arriving. Rows mark themselves with
/// [RowAnchorMarker]. Assumes a vertical, forward axis.
class SliverRowAnchor extends SingleChildRenderObjectWidget {
  const SliverRowAnchor({required Widget sliver, super.key})
    : super(child: sliver);

  @override
  RenderSliverRowAnchor createRenderObject(BuildContext context) =>
      RenderSliverRowAnchor();
}

/// Marks one row for the nearest [SliverRowAnchor]; a table marks each cell
/// of a row under the row's [id], and the row spans its cells.
class RowAnchorMarker extends SingleChildRenderObjectWidget {
  const RowAnchorMarker({required this.id, super.child, super.key});

  final Object id;

  @override
  RenderRowAnchorMarker createRenderObject(BuildContext context) =>
      RenderRowAnchorMarker(id: id);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderRowAnchorMarker renderObject,
  ) => renderObject.id = id;
}

/// The render object of [RowAnchorMarker]: it registers with the nearest
/// [RenderSliverRowAnchor] above it in the same viewport.
class RenderRowAnchorMarker extends RenderProxyBox {
  RenderRowAnchorMarker({required this.id});

  Object id;
  RenderSliverRowAnchor? _anchor;

  /// The height of its own last layout; the anchor may not read [size].
  double? _extent;

  @override
  void performLayout() {
    super.performLayout();
    _extent = size.height;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    var node = parent;
    while (node != null &&
        node is! RenderSliverRowAnchor &&
        node is! RenderAbstractViewport) {
      node = node.parent;
    }
    if (node is RenderSliverRowAnchor) {
      _anchor = node.._markers.add(this);
    }
  }

  @override
  void detach() {
    _anchor?._markers.remove(this);
    _anchor = null;
    super.detach();
  }
}

/// The render object of [SliverRowAnchor].
class RenderSliverRowAnchor extends RenderProxySliver {
  final _markers = <RenderRowAnchorMarker>{};

  /// The row anchored at the last layout and its scroll independent top.
  ({Object id, double top})? _anchored;

  double _topOf(RenderRowAnchorMarker marker) =>
      MatrixUtils.transformPoint(marker.getTransformTo(this), Offset.zero).dy +
      constraints.scrollOffset;

  @override
  void performLayout() {
    assert(
      constraints.axis == Axis.vertical &&
          constraints.growthDirection == GrowthDirection.forward,
      "SliverRowAnchor supports a vertical, forward axis",
    );
    child!.layout(constraints, parentUsesSize: true);
    final childGeometry = child!.geometry!;
    if (childGeometry.scrollOffsetCorrection != null) {
      geometry = childGeometry;
      return;
    }
    // One row per id: it spans from its highest cell to its lowest.
    final rows = <Object, ({double top, double bottom})>{};
    for (final marker in _markers) {
      final extent = marker._extent;
      if (extent == null) continue;
      final top = _topOf(marker);
      final known = rows[marker.id];
      rows[marker.id] = known == null
          ? (top: top, bottom: top + extent)
          : (top: min(known.top, top), bottom: max(known.bottom, top + extent));
    }

    final scrollOffset = constraints.scrollOffset;
    final anchored = _anchored;
    final moved = anchored == null ? null : rows[anchored.id];
    final shift = moved == null ? 0.0 : moved.top - anchored!.top;
    final corrects =
        scrollOffset > precisionErrorTolerance &&
        shift.abs() > precisionErrorTolerance;

    // Anchor on the first row that reaches below the leading edge, in the
    // coordinates the corrected layout will have.
    final applied = corrects ? shift : 0.0;
    ({Object id, double top})? next;
    for (final MapEntry(key: id, value: row) in rows.entries) {
      if (row.bottom - applied <= scrollOffset) continue;
      if (next == null || row.top < next.top) next = (id: id, top: row.top);
    }
    _anchored = next;

    if (corrects) {
      geometry = SliverGeometry(scrollOffsetCorrection: shift);
      return;
    }
    geometry = childGeometry;
  }
}
