part of "portable_connections.dart";

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
  final contentWidth = max(0.0, size.width - indentation);
  final offsets = <Offset>[];
  final targets = <Offset?>[];
  final diagnostics = <String>[];

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
    return max(layout.leadingSpacing, markerDepth + (style?.width ?? 0));
  }
  final trunkStyle = layout.trunkStyle;
  final branchStyle = layout.branchStyles.firstOrNull;
  final trunkDepth = trunkStyle?.startMarker?.inwardExtent ?? 0;
  final branchRadius = branchStyle?.startMarker?.crossAxisExtent ?? 0;
  var spacing = max(layout.leadingSpacing, trunkDepth);
  spacing = max(spacing, branchRadius * 2);
  if (trunkStyle?.startMarker == null && branchStyle?.startMarker == null) {
    return spacing;
  }
  final clearance = max(trunkStyle?.width ?? 0, branchStyle?.width ?? 0);
  return max(spacing, 2 * (trunkDepth + branchRadius + clearance));
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
  return max(layout.itemSpacing, 2 * (markerRadius + (style?.width ?? 0)));
}

double _hierarchyChildX(
  double width,
  double contentLeft,
  double contentWidth,
  double childWidth,
  skir.CrossAxisAlignment_kind alignment,
  TextDirection textDirection,
) {
  final remaining = max(0.0, contentWidth - childWidth);
  return switch (alignment) {
    skir.CrossAxisAlignment_kind.stretchConst => contentLeft,
    skir.CrossAxisAlignment_kind.centerConst => contentLeft + remaining / 2,
    skir.CrossAxisAlignment_kind.startConst =>
      textDirection == TextDirection.ltr ? contentLeft : width - childWidth,
    skir.CrossAxisAlignment_kind.endConst =>
      textDirection == TextDirection.ltr ? width - childWidth : contentLeft,
    skir.CrossAxisAlignment_kind.unknown => contentLeft,
  };
}

Offset? _hierarchyTarget(
  Offset childOffset,
  Size childSize,
  _HierarchyAnchorKind kind,
  double? configuredOffset,
  TextDirection textDirection,
  List<String> diagnostics,
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
