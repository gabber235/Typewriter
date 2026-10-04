part of "portable_connections.dart";

/// Projects anchor declarations into render geometry that a connection layer
/// can discover while painting.
///
/// Anchors are observations of the rendered child, not layout owners. The
/// child keeps its normal rendering and size. Anchor expressions are evaluated
/// in this node's scope, then the anchor surface maps each visible alignment
/// and offset into the connection layer's coordinates. This keeps geometry
/// collection separate from connection path resolution.
extension PresentationAnchorLayoutRendering on PresentationAnchorLayout {
  Widget render(BuildContext context, PortablePresentationScope scope) {
    final resolved = <_ResolvedAnchorPoint>[];
    final diagnostics = <String>[];
    for (final anchor in anchors) {
      final point = anchor._resolve(scope);
      diagnostics.addAll(point.diagnostics);
      if (point.valueOrNull case final value?) resolved.add(value);
    }
    if (diagnostics.isNotEmpty) {
      return _connectionDiagnostics(diagnostics);
    }
    return _PresentationAnchorSurface(
      points: resolved,
      scope: scope,
      occurrenceIdentity: scope.connectionOccurrenceIdentity,
      child: PortablePresentationNodeRenderer(node: child, scope: scope),
    );
  }
}

/// Places a connection resolving surface around the rendered child.
///
/// The layer owns connections declared at this level. It can resolve anchors
/// in its child subtree and explicitly exported anchors from one nested layer,
/// but nested layers remain independent owners of their own connections.
extension ConnectionLayerLayoutRendering on ConnectionLayerLayout {
  Widget render(BuildContext context, PortablePresentationScope scope) =>
      _ConnectionLayerSurface(
        connections: connections.toList(growable: false),
        scope: scope,
        child: PortablePresentationNodeRenderer(node: child, scope: scope),
      );
}

extension on PresentationAnchorPoint {
  /// Resolves visibility and expression driven offset without touching layout.
  ///
  /// Invisible anchors remain in the resolved model as hidden points, which
  /// lets the surface apply one consistent discovery rule and prevents stale
  /// coordinates from being exposed to a connection layer.
  _ConnectionResult<_ResolvedAnchorPoint> _resolve(
    PortablePresentationScope scope,
  ) {
    final visible = switch (visibleIf) {
      null => PortableExpressionAvailable(
        types.DataValue.wrapBoolean(true),
        const [],
      ),
      final expression => scope.evaluate(expression),
    };
    if (visible.diagnostics.isNotEmpty) {
      return _ConnectionResult.failure(visible.diagnostics);
    }
    final visibleValue = visible.valueOrNull;
    if (visibleValue is! types.DataValue_booleanWrapper) {
      return _ConnectionResult.failure([
        "Anchor visibility must evaluate to boolean",
      ]);
    } else if (!visibleValue.value) {
      return _ConnectionResult.success(
        _ResolvedAnchorPoint(
          id: anchorId,
          groupIds: groupIds.toList(growable: false),
          alignment: alignment,
          offset: Offset.zero,
          exportToParent: exportToParent,
          visible: false,
        ),
      );
    }

    final resolvedOffset = offset?._resolve(scope);
    if (resolvedOffset != null && resolvedOffset.diagnostics.isNotEmpty) {
      return _ConnectionResult.failure(resolvedOffset.diagnostics);
    }
    return _ConnectionResult.success(
      _ResolvedAnchorPoint(
        id: anchorId,
        groupIds: groupIds.toList(growable: false),
        alignment: alignment,
        offset: resolvedOffset?.valueOrNull ?? Offset.zero,
        exportToParent: exportToParent,
        visible: true,
      ),
    );
  }
}

extension on PresentationOffset {
  _ConnectionResult<Offset> _resolve(PortablePresentationScope scope) {
    final xValue = scope.evaluate(x);
    final yValue = scope.evaluate(y);
    final diagnostics = [...xValue.diagnostics, ...yValue.diagnostics];
    if (diagnostics.isNotEmpty) return _ConnectionResult.failure(diagnostics);

    final dx = xValue.valueOrNull._connectionNumber;

    final dy = yValue.valueOrNull._connectionNumber;
    if (dx == null || dy == null || !dx.isFinite || !dy.isFinite) {
      return _ConnectionResult.failure([
        "Anchor offset must contain finite numbers",
      ]);
    }
    return _ConnectionResult.success(Offset(dx, dy));
  }
}

extension on types.DataValue? {
  double? get _connectionNumber => switch (this) {
    types.DataValue_floatWrapper(:final value) => value,
    types.DataValue_integerWrapper(:final value) => double.tryParse(value),
    types.DataValue_decimalWrapper(:final value) => double.tryParse(value),
    _ => null,
  };
}

/// Anchor values after expression evaluation, before render transforms.
///
/// Visibility is retained because hidden anchors must not participate in
/// selection or connection lookup. [position] applies writing direction to
/// both the alignment and the configured logical offset.
final class _ResolvedAnchorPoint {
  const _ResolvedAnchorPoint({
    required this.id,
    required this.groupIds,
    required this.alignment,
    required this.offset,
    required this.exportToParent,
    required this.visible,
  });

  final String id;
  final List<String> groupIds;
  final PresentationAnchorAlignment alignment;
  final Offset offset;
  final bool exportToParent;
  final bool visible;

  Offset position(Size size, TextDirection direction) {
    final start = direction == TextDirection.ltr ? 0.0 : size.width;
    final end = direction == TextDirection.ltr ? size.width : 0.0;
    final aligned = switch (alignment.kind) {
      PresentationAnchorAlignment_kind.topStartConst => Offset(start, 0),
      PresentationAnchorAlignment_kind.topCenterConst => Offset(
        size.width / 2,
        0,
      ),
      PresentationAnchorAlignment_kind.topEndConst => Offset(end, 0),
      PresentationAnchorAlignment_kind.centerStartConst => Offset(
        start,
        size.height / 2,
      ),
      PresentationAnchorAlignment_kind.centerConst => size.center(Offset.zero),
      PresentationAnchorAlignment_kind.centerEndConst => Offset(
        end,
        size.height / 2,
      ),
      PresentationAnchorAlignment_kind.bottomStartConst => Offset(
        start,
        size.height,
      ),
      PresentationAnchorAlignment_kind.bottomCenterConst => Offset(
        size.width / 2,
        size.height,
      ),
      PresentationAnchorAlignment_kind.bottomEndConst => Offset(
        end,
        size.height,
      ),
      PresentationAnchorAlignment_kind.unknown => size.center(Offset.zero),
    };
    final logicalOffset = direction == TextDirection.ltr
        ? offset
        : Offset(-offset.dx, offset.dy);
    return aligned + logicalOffset;
  }
}
