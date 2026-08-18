part of "../../layout_renderer.dart";

final class _HierarchySequenceRenderer extends StatefulWidget {
  const _HierarchySequenceRenderer({
    required this.layout,
    required this.scope,
    required this.itemScopes,
    required this.children,
  });

  final HierarchySequenceLayout layout;
  final PresentationRenderScope scope;
  final List<PresentationRenderScope> itemScopes;
  final List<Widget> children;

  @override
  State<_HierarchySequenceRenderer> createState() =>
      _HierarchySequenceRendererState();
}

final class _HierarchySequenceRendererState
    extends State<_HierarchySequenceRenderer> {
  List<TypeDiagnostic> _geometryDiagnostics = const [];
  List<TypeDiagnostic>? _pendingDiagnostics;
  bool _updateScheduled = false;

  void _handleDiagnostics(List<TypeDiagnostic> diagnostics) {
    if (listEquals(_geometryDiagnostics, diagnostics) ||
        listEquals(_pendingDiagnostics, diagnostics)) {
      return;
    }
    _pendingDiagnostics = diagnostics;
    if (_updateScheduled) return;
    _updateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScheduled = false;
      final pending = _pendingDiagnostics;
      _pendingDiagnostics = null;
      if (!mounted || pending == null) return;
      if (listEquals(_geometryDiagnostics, pending)) return;
      setState(() => _geometryDiagnostics = pending);
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.children.length == widget.itemScopes.length);
    final layout = _resolveHierarchyLayout(
      widget.layout,
      widget.scope,
      widget.itemScopes,
    );
    final diagnostics = [...layout.diagnostics, ..._geometryDiagnostics];
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        _HierarchyRenderSurface(
          layout: layout,
          textDirection: Directionality.of(context),
          onDiagnosticsChanged: _handleDiagnostics,
          children: widget.children,
        ),
        if (diagnostics.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: presentationDiagnostic(context, diagnostics),
          ),
      ],
    );
  }
}

_ResolvedHierarchyLayout _resolveHierarchyLayout(
  HierarchySequenceLayout layout,
  PresentationRenderScope scope,
  List<PresentationRenderScope> itemScopes,
) {
  final diagnostics = <TypeDiagnostic>[];
  final itemSpacing = _evaluateNonnegative(
    layout.itemSpacing,
    scope,
    "hierarchy item spacing",
  );
  final indentation = _evaluateNonnegative(
    layout.indentation,
    scope,
    "hierarchy indentation",
  );
  final leadingSpacing = _evaluateNonnegative(
    layout.leadingSpacing,
    scope,
    "hierarchy leading spacing",
  );
  final flatten = _evaluateBoolean(layout.flattenSingleItem, scope, true);
  diagnostics.addAll([
    ...itemSpacing.diagnostics,
    ...indentation.diagnostics,
    ...leadingSpacing.diagnostics,
    ...flatten.diagnostics,
  ]);
  final anchorOffsets = <double?>[];
  final anchorKind = switch (layout.itemAnchor) {
    StartConnectorAnchor() => _HierarchyAnchorKind.start,
    CenterConnectorAnchor() => _HierarchyAnchorKind.center,
    OffsetConnectorAnchor(:final value) => () {
      for (final itemScope in itemScopes) {
        final offset = _evaluateNonnegative(
          value,
          itemScope,
          "hierarchy item anchor offset",
        );
        diagnostics.addAll(offset.diagnostics);
        anchorOffsets.add(offset.valueOrNull);
      }
      return _HierarchyAnchorKind.offset;
    }(),
  };
  if (anchorKind != _HierarchyAnchorKind.offset) {
    anchorOffsets.addAll(List<double?>.filled(itemScopes.length, null));
  }
  final unaryScope = itemScopes.firstOrNull ?? scope;
  final unary = _resolveConnectorStyle(
    layout.unaryConnector,
    unaryScope,
    diagnostics,
  );
  final trunk = _resolveConnectorStyle(
    layout.trunkConnector,
    scope,
    diagnostics,
  );
  final branches = [
    for (final itemScope in itemScopes)
      _resolveConnectorStyle(layout.branchConnector, itemScope, diagnostics),
  ];
  return _ResolvedHierarchyLayout(
    itemSpacing: itemSpacing.valueOrNull ?? 0,
    indentation: indentation.valueOrNull ?? 0,
    leadingSpacing: leadingSpacing.valueOrNull ?? 0,
    flattenSingleItem: flatten.valueOrNull ?? true,
    crossAxisAlignment: layout.crossAxisAlignment,
    anchorKind: anchorKind,
    anchorOffsets: anchorOffsets,
    unaryStyle: unary,
    trunkStyle: trunk,
    branchStyles: branches,
    diagnostics: diagnostics,
  );
}
