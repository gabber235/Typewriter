part of "editor_presentation_encoder.dart";

extension SkirPresentationConnectionEncoder on SkirPresentationEncoder {
  TypeResult<wire.PresentationElement> _connectionLayer(
    ConnectionLayerElement value,
  ) {
    final child = encodeNode(value.child);
    final connections = <wire.PresentationConnection>[];
    final diagnostics = [...child.diagnostics];
    for (final value in value.connections) {
      final connection = _connection(value);
      diagnostics.addAll(connection.diagnostics);
      if (connection.valueOrNull case final item?) connections.add(item);
    }
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.PresentationElement.createConnectionLayer(
              child: child.valueOrNull!,
              connections: connections,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.PresentationConnection> _connection(
    PresentationConnection value,
  ) => switch (value) {
    AnchoredConnection() => _anchoredConnection(value),
    AnchoredConnectionBundle() => _anchoredBundle(value),
  };

  TypeResult<wire.PresentationConnection> _anchoredConnection(
    AnchoredConnection value,
  ) {
    final source = _selector(value.source);
    final target = _selector(value.target);
    final path = _path(value.path);
    final style = _connectorStyle(value.style);
    final markers = _markers(value.markers);
    final visible = _optional(value.visibleIf);
    final diagnostics = [
      ...path.diagnostics,
      ...style.diagnostics,
      ...markers.diagnostics,
      ...visible.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.PresentationConnection.createConnection(
              source: source,
              target: target,
              path: path.valueOrNull!,
              style: style.valueOrNull!,
              markers: markers.valueOrNull!,
              visibleIf: visible.valueOrNull,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.PresentationConnection> _anchoredBundle(
    AnchoredConnectionBundle value,
  ) {
    final path = _bundlePath(value.path);
    final trunk = _connectorStyle(value.trunkStyle);
    final branch = _connectorStyle(value.branchStyle);
    final trunkMarkers = _markers(value.trunkMarkers);
    final branchMarkers = _markers(value.branchMarkers);
    final visible = _optional(value.visibleIf);
    final diagnostics = [
      ...path.diagnostics,
      ...trunk.diagnostics,
      ...branch.diagnostics,
      ...trunkMarkers.diagnostics,
      ...branchMarkers.diagnostics,
      ...visible.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.PresentationConnection.createBundle(
              source: _selector(value.source),
              targets: _selector(value.targets),
              path: path.valueOrNull!,
              trunkStyle: trunk.valueOrNull!,
              branchStyle: branch.valueOrNull!,
              trunkMarkers: trunkMarkers.valueOrNull!,
              branchMarkers: branchMarkers.valueOrNull!,
              visibleIf: visible.valueOrNull,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  wire.PresentationAnchorSelector _selector(PresentationAnchorSelector value) =>
      switch (value) {
        LocalAnchor(:final id) => wire.PresentationAnchorSelector.wrapLocal(id),
        ExportedAnchorGroup(:final groupId) =>
          wire.PresentationAnchorSelector.wrapExportedGroup(groupId),
      };

  TypeResult<wire.ConnectorStroke> _stroke(ConnectorStroke value) =>
      combineResults(
        expressions.encode(value.color),
        expressions.encode(value.width),
        (color, width) => wire.ConnectorStroke(color: color, width: width),
      );

  TypeResult<wire.ConnectorStyle> _connectorStyle(ConnectorStyle value) {
    final stroke = _stroke(value.stroke);
    final radius = expressions.encode(value.cornerRadius);
    final start = _endpointMarker(value.startMarker);
    final end = _endpointMarker(value.endMarker);
    final diagnostics = [
      ...stroke.diagnostics,
      ...radius.diagnostics,
      ...start.diagnostics,
      ...end.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.ConnectorStyle(
              stroke: stroke.valueOrNull!,
              cornerRadius: radius.valueOrNull!,
              startMarker: start.valueOrNull,
              endMarker: end.valueOrNull,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.ConnectorEndpointMarker?> _endpointMarker(
    ConnectorEndpointMarker? value,
  ) {
    if (value == null) return const TypeResult.success(null);
    return switch (value) {
      ArrowConnectorMarker(:final size) =>
        expressions
            .encode(size)
            .mapValue(
              (size) => wire.ConnectorEndpointMarker.createArrow(size: size),
            ),
      CircleConnectorMarker(:final diameter) =>
        expressions
            .encode(diameter)
            .mapValue(
              (diameter) =>
                  wire.ConnectorEndpointMarker.createCircle(diameter: diameter),
            ),
    };
  }

  TypeResult<List<wire.ConnectionMarker>> _markers(
    Iterable<ConnectionMarker> values,
  ) {
    final markers = <wire.ConnectionMarker>[];
    final diagnostics = <TypeDiagnostic>[];
    for (final value in values) {
      final node = encodeNode(value.node);
      final position = expressions.encode(value.position);
      final align = expressions.encode(value.alignToPath);
      diagnostics
        ..addAll(node.diagnostics)
        ..addAll(position.diagnostics)
        ..addAll(align.diagnostics);
      if (node.valueOrNull case final nodeValue?) {
        if (position.valueOrNull case final positionValue?) {
          if (align.valueOrNull case final alignValue?) {
            markers.add(
              wire.ConnectionMarker(
                node: nodeValue,
                position: positionValue,
                alignToPath: alignValue,
                scope: value.scope._encode,
              ),
            );
          }
        }
      }
    }
    return diagnostics.isEmpty
        ? TypeResult.success(markers)
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.ConnectionPath> _path(ConnectionPath value) =>
      switch (value) {
        StraightConnectionPath() => const TypeResult.success(
          wire.ConnectionPath.straight,
        ),
        OrthogonalPath(:final path) =>
          expressions
              .encode(path.bendPosition)
              .mapValue(
                (bend) =>
                    wire.ConnectionPath.createOrthogonal(bendPosition: bend),
              ),
        CurvedPath(:final path) => combineResults(
          _offset(path.sourceControlOffset),
          _offset(path.targetControlOffset),
          (source, target) => wire.ConnectionPath.createCurved(
            sourceControlOffset: source,
            targetControlOffset: target,
          ),
        ),
      };

  TypeResult<wire.ConnectionBundlePath> _bundlePath(
    ConnectionBundlePath value,
  ) => switch (value) {
    FanBundlePath() => const TypeResult.success(wire.ConnectionBundlePath.fan),
    OrthogonalBundlePath(:final path) =>
      expressions
          .encode(path.bendPosition)
          .mapValue(
            (bend) => wire.ConnectionBundlePath.createOrthogonal(
              axis: path.axis == ConnectionAxis.horizontal
                  ? wire.ConnectionAxis.horizontal
                  : wire.ConnectionAxis.vertical,
              bendPosition: bend,
            ),
          ),
  };
}

extension on PresentationAnchorAlignment {
  wire.PresentationAnchorAlignment get _encode => switch (this) {
    PresentationAnchorAlignment.topStart =>
      wire.PresentationAnchorAlignment.topStart,
    PresentationAnchorAlignment.topCenter =>
      wire.PresentationAnchorAlignment.topCenter,
    PresentationAnchorAlignment.topEnd =>
      wire.PresentationAnchorAlignment.topEnd,
    PresentationAnchorAlignment.centerStart =>
      wire.PresentationAnchorAlignment.centerStart,
    PresentationAnchorAlignment.center =>
      wire.PresentationAnchorAlignment.center,
    PresentationAnchorAlignment.centerEnd =>
      wire.PresentationAnchorAlignment.centerEnd,
    PresentationAnchorAlignment.bottomStart =>
      wire.PresentationAnchorAlignment.bottomStart,
    PresentationAnchorAlignment.bottomCenter =>
      wire.PresentationAnchorAlignment.bottomCenter,
    PresentationAnchorAlignment.bottomEnd =>
      wire.PresentationAnchorAlignment.bottomEnd,
  };
}

extension on ConnectionExpressionScope {
  wire.ConnectionExpressionScope get _encode => switch (this) {
    ConnectionExpressionScope.layer => wire.ConnectionExpressionScope.layer,
    ConnectionExpressionScope.source => wire.ConnectionExpressionScope.source,
    ConnectionExpressionScope.target => wire.ConnectionExpressionScope.target,
  };
}
