part of "../../layout_renderer.dart";

_ConnectionResolution _resolveConnections({
  required List<PresentationConnection> connections,
  required PresentationRenderScope scope,
  required TextDirection textDirection,
  required List<_AnchorSnapshot> localAnchors,
  required List<_AnchorSnapshot> exportedAnchors,
}) {
  final strokes = <_ResolvedStrokePath>[];
  final markers = <_ResolvedMarker>[];
  final diagnostics = <TypeDiagnostic>[];
  final local = [for (final anchor in localAnchors) _LayerAnchor(anchor)];
  final exported = [for (final anchor in exportedAnchors) _LayerAnchor(anchor)];
  final localIds = <String, int>{};
  for (final anchor in local) {
    localIds.update(
      anchor.snapshot.id,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
  }
  for (final entry in localIds.entries.where((entry) => entry.value > 1)) {
    diagnostics.add(
      _connectionDiagnostic("Duplicate local anchor identifier: ${entry.key}"),
    );
  }
  for (final (connectionIndex, connection) in connections.indexed) {
    final visible = _evaluateBoolean(connection.visibleIf, scope, true);
    diagnostics.addAll(visible.diagnostics);
    if (visible.valueOrNull != true) continue;
    switch (connection) {
      case final AnchoredConnection connection:
        _resolveSingle(
          connection,
          (connectionIndex, connection),
          scope,
          textDirection,
          local,
          exported,
          strokes,
          markers,
          diagnostics,
        );
      case final AnchoredConnectionBundle connection:
        _resolveBundle(
          connection,
          (connectionIndex, connection),
          scope,
          local,
          exported,
          strokes,
          markers,
          diagnostics,
        );
    }
  }
  return _ConnectionResolution(
    strokes: strokes,
    markers: markers,
    diagnostics: diagnostics,
  );
}

void _resolveSingle(
  AnchoredConnection connection,
  Object connectionIdentity,
  PresentationRenderScope layerScope,
  TextDirection textDirection,
  List<_LayerAnchor> local,
  List<_LayerAnchor> exported,
  List<_ResolvedStrokePath> strokes,
  List<_ResolvedMarker> markers,
  List<TypeDiagnostic> diagnostics,
) {
  final sources = _select(connection.source, local, exported);
  final targets = _select(connection.target, local, exported);
  if (sources.length != 1) {
    diagnostics.add(
      _connectionDiagnostic(
        sources.isEmpty
            ? "Connection source anchor is missing"
            : "Connection source anchor is ambiguous",
      ),
    );
    return;
  }
  if (targets.length != 1) {
    diagnostics.add(
      _connectionDiagnostic(
        targets.isEmpty
            ? "Connection target anchor is missing"
            : "Connection target anchor is ambiguous",
      ),
    );
    return;
  }
  final source = sources.single;
  final target = targets.single;
  final style = _resolveConnectorStyle(
    connection.style,
    target.snapshot.scope,
    diagnostics,
  );
  if (style == null) return;
  final path = _resolvePath(
    connection.path,
    source,
    target,
    textDirection,
    style.cornerRadius,
    diagnostics,
  );
  if (path == null) return;
  strokes.add(_ResolvedStrokePath(path: path, style: style));
  _resolveMarkers(
    templates: connection.markers,
    path: path,
    layerScope: layerScope,
    source: source,
    target: target,
    identity: connectionIdentity,
    output: markers,
    diagnostics: diagnostics,
  );
}

void _resolveBundle(
  AnchoredConnectionBundle connection,
  Object connectionIdentity,
  PresentationRenderScope layerScope,
  List<_LayerAnchor> local,
  List<_LayerAnchor> exported,
  List<_ResolvedStrokePath> strokes,
  List<_ResolvedMarker> markers,
  List<TypeDiagnostic> diagnostics,
) {
  final sources = _select(connection.source, local, exported);
  final targets = _select(connection.targets, local, exported);
  if (sources.length != 1) {
    diagnostics.add(
      _connectionDiagnostic(
        sources.isEmpty
            ? "Bundle source anchor is missing"
            : "Bundle source anchor is ambiguous",
      ),
    );
    return;
  }
  if (targets.isEmpty) return;
  final source = sources.single;
  final trunkStyle = _resolveConnectorStyle(
    connection.trunkStyle,
    source.snapshot.scope,
    diagnostics,
  );
  final branchStyles = [
    for (final target in targets)
      _resolveConnectorStyle(
        connection.branchStyle,
        target.snapshot.scope,
        diagnostics,
      ),
  ];
  final paths = _resolveBundlePaths(
    connection.path,
    source,
    targets,
    trunkStyle?.cornerRadius ?? 0,
    [for (final style in branchStyles) style?.cornerRadius ?? 0],
    diagnostics,
  );
  if (paths == null) return;
  if (paths.trunk case final trunk? when trunkStyle != null) {
    strokes.add(_ResolvedStrokePath(path: trunk, style: trunkStyle));
    _resolveMarkers(
      templates: connection.trunkMarkers,
      path: trunk,
      layerScope: layerScope,
      source: source,
      target: targets.first,
      identity: (connectionIdentity, "trunk"),
      output: markers,
      diagnostics: diagnostics,
      allowTargetScope: false,
    );
  }
  for (var index = 0; index < targets.length; index++) {
    final target = targets[index];
    final path = paths.branches[index];
    final style = branchStyles[index];
    if (style != null) {
      strokes.add(_ResolvedStrokePath(path: path, style: style));
    }
    _resolveMarkers(
      templates: connection.branchMarkers,
      path: path,
      layerScope: layerScope,
      source: source,
      target: target,
      identity: (connectionIdentity, target.snapshot.occurrenceIdentity, index),
      output: markers,
      diagnostics: diagnostics,
    );
  }
}

List<_LayerAnchor> _select(
  PresentationAnchorSelector selector,
  List<_LayerAnchor> local,
  List<_LayerAnchor> exported,
) => switch (selector) {
  LocalAnchor(:final id) =>
    local.where((anchor) => anchor.snapshot.id == id).toList(),
  ExportedAnchorGroup(:final groupId) =>
    exported
        .where((anchor) => anchor.snapshot.groupIds.contains(groupId))
        .toList(),
};
