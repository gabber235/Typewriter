part of "../../layout_renderer.dart";

enum _HierarchyAnchorKind { start, center, offset }

final class _ResolvedHierarchyLayout {
  const _ResolvedHierarchyLayout({
    required this.itemSpacing,
    required this.indentation,
    required this.leadingSpacing,
    required this.flattenSingleItem,
    required this.crossAxisAlignment,
    required this.anchorKind,
    required this.anchorOffsets,
    required this.unaryStyle,
    required this.trunkStyle,
    required this.branchStyles,
    required this.diagnostics,
  });

  final double itemSpacing;
  final double indentation;
  final double leadingSpacing;
  final bool flattenSingleItem;
  final PresentationCrossAxisAlignment crossAxisAlignment;
  final _HierarchyAnchorKind anchorKind;
  final List<double?> anchorOffsets;
  final _ResolvedConnectorStyle? unaryStyle;
  final _ResolvedConnectorStyle? trunkStyle;
  final List<_ResolvedConnectorStyle?> branchStyles;
  final List<TypeDiagnostic> diagnostics;
}

final class _HierarchyGeometry {
  const _HierarchyGeometry({
    required this.size,
    required this.childOffsets,
    required this.strokes,
    required this.diagnostics,
  });

  final Size size;
  final List<Offset> childOffsets;
  final List<_ResolvedStrokePath> strokes;
  final List<TypeDiagnostic> diagnostics;
}

final class _HierarchyParentData extends ContainerBoxParentData<RenderBox> {}
