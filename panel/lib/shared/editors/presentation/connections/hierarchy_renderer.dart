part of "portable_connections.dart";

extension PortableHierarchySequenceRendering on HierarchySequenceLayout {
  Widget renderPortableHierarchy({
    required PortablePresentationScope scope,
    required List<PortablePresentationScope> itemScopes,
    required List<Widget> children,
  }) => _PortableHierarchySequenceRenderer(
    layout: this,
    scope: scope,
    itemScopes: itemScopes,
    children: children,
  );
}

final class _PortableHierarchySequenceRenderer extends StatefulWidget {
  const _PortableHierarchySequenceRenderer({
    required this.layout,
    required this.scope,
    required this.itemScopes,
    required this.children,
  });

  final HierarchySequenceLayout layout;
  final PortablePresentationScope scope;
  final List<PortablePresentationScope> itemScopes;
  final List<Widget> children;

  @override
  State<_PortableHierarchySequenceRenderer> createState() =>
      _PortableHierarchySequenceRendererState();
}

final class _PortableHierarchySequenceRendererState
    extends State<_PortableHierarchySequenceRenderer> {
  List<String> _geometryDiagnostics = const [];
  List<String>? _pendingDiagnostics;
  bool _updateScheduled = false;

  void _handleDiagnostics(List<String> diagnostics) {
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
    final layout = _resolvePortableHierarchyLayout(
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
            child: _connectionDiagnostics(diagnostics),
          ),
      ],
    );
  }
}

_ResolvedHierarchyLayout _resolvePortableHierarchyLayout(
  HierarchySequenceLayout layout,
  PortablePresentationScope scope,
  List<PortablePresentationScope> itemScopes,
) {
  final diagnostics = <String>[];
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
    ConnectorAnchor_offsetWrapper(:final value) => () {
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
    _ when layout.itemAnchor.kind == ConnectorAnchor_kind.centerConst =>
      _HierarchyAnchorKind.center,
    _ => _HierarchyAnchorKind.start,
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
    crossAxisAlignment: layout.crossAxisAlignment.kind,
    anchorKind: anchorKind,
    anchorOffsets: anchorOffsets,
    unaryStyle: unary,
    trunkStyle: trunk,
    branchStyles: branches,
    diagnostics: diagnostics,
  );
}
