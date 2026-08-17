part of "../../layout_renderer.dart";

_HierarchyGeometry _resolveHierarchyGeometry({
  required Size size,
  required List<Size> childSizes,
  required _ResolvedHierarchyLayout layout,
  required double leadingSpacing,
  required List<double> itemSpacings,
  required TextDirection textDirection,
}) {
  if (childSizes.isEmpty) {
    return _HierarchyGeometry(
      size: size,
      childOffsets: const [],
      strokes: const [],
      diagnostics: const [],
    );
  }
  final branching = childSizes.length > 1 || !layout.flattenSingleItem;
  final indentation = branching ? layout.indentation : 0.0;
  final contentLeft = textDirection == TextDirection.ltr ? indentation : 0.0;
  final contentWidth = math.max(0.0, size.width - indentation);
  final offsets = <Offset>[];
  final targets = <Offset?>[];
  final diagnostics = <TypeDiagnostic>[];
  var y = leadingSpacing;
  for (var index = 0; index < childSizes.length; index++) {
    final childSize = childSizes[index];
    final x = _hierarchyChildX(
      size.width,
      contentLeft,
      contentWidth,
      childSize.width,
      layout.crossAxisAlignment,
      textDirection,
    );
    final childOffset = Offset(x, y);
    offsets.add(childOffset);
    targets.add(
      _hierarchyTarget(
        childOffset,
        childSize,
        layout.anchorKind,
        layout.anchorOffsets[index],
        textDirection,
        diagnostics,
      ),
    );
    y += childSize.height;
    if (index < itemSpacings.length) y += itemSpacings[index];
  }
  final strokes = branching
      ? _branchingHierarchyStrokes(
          size.width,
          targets,
          layout,
          leadingSpacing,
          itemSpacings,
          textDirection,
        )
      : _unaryHierarchyStrokes(targets.single, layout);
  return _HierarchyGeometry(
    size: size,
    childOffsets: offsets,
    strokes: strokes,
    diagnostics: diagnostics,
  );
}

double _effectiveHierarchyLeadingSpacing(
  _ResolvedHierarchyLayout layout, {
  required bool branching,
}) {
  if (!branching) {
    final style = layout.unaryStyle;
    final markerDepth = style?.startMarker?.inwardExtent ?? 0;
    return math.max(layout.leadingSpacing, markerDepth + (style?.width ?? 0));
  }

  final trunkStyle = layout.trunkStyle;
  final branchStyle = layout.branchStyles.firstOrNull;
  final trunkMarker = trunkStyle?.startMarker;
  final branchMarker = branchStyle?.startMarker;
  final trunkDepth = trunkMarker?.inwardExtent ?? 0;
  final branchRadius = branchMarker?.crossAxisExtent ?? 0;
  var spacing = math.max(layout.leadingSpacing, trunkDepth);
  spacing = math.max(spacing, branchRadius * 2);
  if (trunkMarker == null && branchMarker == null) return spacing;

  final clearance = math.max(trunkStyle?.width ?? 0, branchStyle?.width ?? 0);
  return math.max(spacing, 2 * (trunkDepth + branchRadius + clearance));
}

List<double> _effectiveHierarchyItemSpacings(_ResolvedHierarchyLayout layout) =>
    [
      for (
        var targetIndex = 1;
        targetIndex < layout.branchStyles.length;
        targetIndex++
      )
        _effectiveHierarchyItemSpacing(layout, targetIndex),
    ];

double _effectiveHierarchyItemSpacing(
  _ResolvedHierarchyLayout layout,
  int targetIndex,
) {
  final style = layout.branchStyles[targetIndex];
  final markerRadius = style?.startMarker?.crossAxisExtent ?? 0;
  if (markerRadius == 0) return layout.itemSpacing;
  return math.max(layout.itemSpacing, 2 * (markerRadius + (style?.width ?? 0)));
}

double _hierarchyChildX(
  double width,
  double contentLeft,
  double contentWidth,
  double childWidth,
  PresentationCrossAxisAlignment alignment,
  TextDirection textDirection,
) {
  final remaining = math.max(0.0, contentWidth - childWidth);
  return switch (alignment) {
    PresentationCrossAxisAlignment.stretch => contentLeft,
    PresentationCrossAxisAlignment.center => contentLeft + remaining / 2,
    PresentationCrossAxisAlignment.start =>
      textDirection == TextDirection.ltr ? contentLeft : width - childWidth,
    PresentationCrossAxisAlignment.end =>
      textDirection == TextDirection.ltr ? width - childWidth : contentLeft,
  };
}

Offset? _hierarchyTarget(
  Offset childOffset,
  Size childSize,
  _HierarchyAnchorKind kind,
  double? configuredOffset,
  TextDirection textDirection,
  List<TypeDiagnostic> diagnostics,
) {
  final logicalOffset = switch (kind) {
    _HierarchyAnchorKind.start => 0.0,
    _HierarchyAnchorKind.center => childSize.width / 2,
    _HierarchyAnchorKind.offset => configuredOffset,
  };
  if (logicalOffset == null) return null;
  if (logicalOffset > childSize.width) {
    diagnostics.add(
      _connectionDiagnostic(
        "Hierarchy item anchor offset exceeds the child width",
      ),
    );
    return null;
  }
  final x = textDirection == TextDirection.ltr
      ? childOffset.dx + logicalOffset
      : childOffset.dx + childSize.width - logicalOffset;
  return Offset(x, childOffset.dy);
}

List<_ResolvedStrokePath> _unaryHierarchyStrokes(
  Offset? target,
  _ResolvedHierarchyLayout layout,
) {
  final style = layout.unaryStyle;
  if (target == null || style == null) return const [];
  return [
    _ResolvedStrokePath(
      path: Path()
        ..moveTo(target.dx, 0)
        ..lineTo(target.dx, target.dy),
      style: style,
    ),
  ];
}

List<_ResolvedStrokePath> _branchingHierarchyStrokes(
  double width,
  List<Offset?> targets,
  _ResolvedHierarchyLayout layout,
  double leadingSpacing,
  List<double> itemSpacings,
  TextDirection textDirection,
) {
  final resolvedTargets = [
    for (final (index, target) in targets.indexed)
      if (target != null) (index, target),
  ];
  if (resolvedTargets.isEmpty) return const [];
  final trunkX = textDirection == TextDirection.ltr
      ? layout.indentation / 2
      : width - layout.indentation / 2;
  final junctions = [
    for (final (index, target) in resolvedTargets)
      Offset(
        trunkX,
        target.dy - (index == 0 ? leadingSpacing : itemSpacings[index - 1]) / 2,
      ),
  ];
  return [
    if (layout.trunkStyle case final style?)
      _ResolvedStrokePath(
        path: Path()
          ..moveTo(trunkX, 0)
          ..lineTo(trunkX, junctions.last.dy),
        style: style,
      ),
    for (var index = 0; index < resolvedTargets.length; index++)
      if (layout.branchStyles[resolvedTargets[index].$1] case final style?)
        _ResolvedStrokePath(
          path: _roundedPath([
            junctions[index],
            Offset(resolvedTargets[index].$2.dx, junctions[index].dy),
            resolvedTargets[index].$2,
          ], style.cornerRadius),
          style: style,
        ),
  ];
}
