part of "../../layout_renderer.dart";

final class _HierarchyRenderSurface extends MultiChildRenderObjectWidget {
  const _HierarchyRenderSurface({
    required this.layout,
    required this.textDirection,
    required this.onDiagnosticsChanged,
    required super.children,
  });

  final _ResolvedHierarchyLayout layout;
  final TextDirection textDirection;
  final ValueChanged<List<TypeDiagnostic>> onDiagnosticsChanged;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHierarchySurface(
        layout: layout,
        textDirection: textDirection,
        onDiagnosticsChanged: onDiagnosticsChanged,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderHierarchySurface renderObject,
  ) {
    renderObject.update(
      layout: layout,
      textDirection: textDirection,
      onDiagnosticsChanged: onDiagnosticsChanged,
    );
  }
}

final class _RenderHierarchySurface extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _HierarchyParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _HierarchyParentData> {
  _RenderHierarchySurface({
    required _ResolvedHierarchyLayout layout,
    required TextDirection textDirection,
    required ValueChanged<List<TypeDiagnostic>> onDiagnosticsChanged,
  }) : _layout = layout,
       _textDirection = textDirection,
       _onDiagnosticsChanged = onDiagnosticsChanged;

  _ResolvedHierarchyLayout _layout;
  TextDirection _textDirection;
  ValueChanged<List<TypeDiagnostic>> _onDiagnosticsChanged;
  List<_ResolvedStrokePath> _strokes = const [];
  List<TypeDiagnostic> _diagnostics = const [];

  List<_ResolvedStrokePath> get debugStrokes => _strokes;
  List<TypeDiagnostic> get debugDiagnostics => _diagnostics;

  void update({
    required _ResolvedHierarchyLayout layout,
    required TextDirection textDirection,
    required ValueChanged<List<TypeDiagnostic>> onDiagnosticsChanged,
  }) {
    _layout = layout;
    _textDirection = textDirection;
    _onDiagnosticsChanged = onDiagnosticsChanged;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _HierarchyParentData) {
      child.parentData = _HierarchyParentData();
    }
  }

  @override
  void performLayout() {
    final children = getChildrenAsList();
    if (children.isEmpty) {
      size = constraints.constrain(Size.zero);
      _updateGeometry(
        _HierarchyGeometry(
          size: size,
          childOffsets: const [],
          strokes: const [],
          diagnostics: const [],
        ),
      );
      return;
    }
    final branching = children.length > 1 || !_layout.flattenSingleItem;
    final leadingSpacing = _effectiveHierarchyLeadingSpacing(
      _layout,
      branching: branching,
    );
    final itemSpacings = branching
        ? _effectiveHierarchyItemSpacings(_layout)
        : List<double>.filled(
            math.max(0, children.length - 1),
            _layout.itemSpacing,
          );
    final indentation = branching ? _layout.indentation : 0.0;
    final boundedWidth = constraints.hasBoundedWidth;
    final contentMaximum = boundedWidth
        ? math.max(0.0, constraints.maxWidth - indentation)
        : double.infinity;
    final looseConstraints = BoxConstraints(maxWidth: contentMaximum);
    for (final child in children) {
      child.layout(looseConstraints, parentUsesSize: true);
    }
    final naturalContentWidth = children
        .map((child) => child.size.width)
        .fold(0.0, math.max);
    final width = constraints.constrainWidth(
      boundedWidth ? constraints.maxWidth : indentation + naturalContentWidth,
    );
    final contentWidth = math.max(0.0, width - indentation);
    if (_layout.crossAxisAlignment == PresentationCrossAxisAlignment.stretch) {
      final stretched = BoxConstraints.tightFor(width: contentWidth);
      for (final child in children) {
        child.layout(stretched, parentUsesSize: true);
      }
    }
    final height =
        leadingSpacing +
        children.fold(0.0, (sum, child) => sum + child.size.height) +
        itemSpacings.fold(0.0, (sum, spacing) => sum + spacing);
    size = constraints.constrain(Size(width, height));
    final geometry = _resolveHierarchyGeometry(
      size: size,
      childSizes: [for (final child in children) child.size],
      layout: _layout,
      leadingSpacing: leadingSpacing,
      itemSpacings: itemSpacings,
      textDirection: _textDirection,
    );
    for (var index = 0; index < children.length; index++) {
      (children[index].parentData! as _HierarchyParentData).offset =
          geometry.childOffsets[index];
    }
    _updateGeometry(geometry);
  }

  void _updateGeometry(_HierarchyGeometry geometry) {
    _strokes = geometry.strokes;
    if (!listEquals(_diagnostics, geometry.diagnostics)) {
      _diagnostics = geometry.diagnostics;
      _onDiagnosticsChanged(_diagnostics);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas
      ..save()
      ..translate(offset.dx, offset.dy);
    _paintResolvedConnectorPaths(canvas, _strokes);
    canvas.restore();
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
