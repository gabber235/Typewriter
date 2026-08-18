part of "editor_presentation_codec.dart";

extension SkirPresentationConnectionDecoder on SkirPresentationDecoder {
  TypeResult<PresentationElement> _connectionLayer(
    wire.ConnectionLayerLayout value,
  ) {
    final connections = <PresentationConnection>[];
    final diagnostics = <TypeDiagnostic>[];
    for (final value in value.connections) {
      final connection = _connection(value);
      diagnostics.addAll(connection.diagnostics);
      if (connection.valueOrNull case final item?) connections.add(item);
    }
    if (connections.isEmpty) {
      diagnostics.add(wireDiagnostic("Presentation connections are empty"));
    }
    return diagnostics.isEmpty
        ? TypeResult.success(
            ConnectionLayerElement(
              child: decodeNode(value.child),
              connections: connections,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<PresentationConnection> _connection(
    wire.PresentationConnection value,
  ) => switch (value) {
    wire.PresentationConnection_connectionWrapper(:final value) =>
      _anchoredConnection(value),
    wire.PresentationConnection_bundleWrapper(:final value) => _anchoredBundle(
      value,
    ),
    wire.PresentationConnection_unknown() => invalidWire(
      "Unknown presentation connection",
    ),
  };

  TypeResult<PresentationConnection> _anchoredConnection(
    wire.AnchoredConnection value,
  ) {
    final source = _selector(value.source);
    final target = _selector(value.target);
    final path = _path(value.path);
    final style = _connectorStyle(value.style);
    final markers = _markers(value.markers);
    final visible = _optionalExpression(value.visibleIf);
    final diagnostics = [
      ...source.diagnostics,
      ...target.diagnostics,
      ...path.diagnostics,
      ...style.diagnostics,
      ...markers.diagnostics,
      ...visible.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            PresentationConnection.connection(
              source: source.valueOrNull!,
              target: target.valueOrNull!,
              path: path.valueOrNull!,
              style: style.valueOrNull!,
              markers: markers.valueOrNull!,
              visibleIf: visible.valueOrNull,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<PresentationConnection> _anchoredBundle(
    wire.AnchoredConnectionBundle value,
  ) {
    final source = _selector(value.source);
    final targets = _selector(value.targets);
    final path = _bundlePath(value.path);
    final trunk = _connectorStyle(value.trunkStyle);
    final branch = _connectorStyle(value.branchStyle);
    final trunkMarkers = _markers(value.trunkMarkers);
    final branchMarkers = _markers(value.branchMarkers);
    final visible = _optionalExpression(value.visibleIf);
    final diagnostics = [
      ...source.diagnostics,
      ...targets.diagnostics,
      ...path.diagnostics,
      ...trunk.diagnostics,
      ...branch.diagnostics,
      ...trunkMarkers.diagnostics,
      ...branchMarkers.diagnostics,
      ...visible.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            PresentationConnection.bundle(
              source: source.valueOrNull!,
              targets: targets.valueOrNull!,
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

  TypeResult<PresentationAnchorSelector> _selector(
    wire.PresentationAnchorSelector value,
  ) => switch (value) {
    wire.PresentationAnchorSelector_localWrapper(:final value)
        when value.isNotEmpty =>
      TypeResult.success(LocalAnchor(value)),
    wire.PresentationAnchorSelector_exportedGroupWrapper(:final value)
        when value.isNotEmpty =>
      TypeResult.success(ExportedAnchorGroup(value)),
    _ => invalidWire("Invalid presentation anchor selector"),
  };

  TypeResult<ConnectorStroke> _stroke(wire.ConnectorStroke value) =>
      combineResults(
        expressions.decode(value.color),
        expressions.decode(value.width),
        (color, width) => ConnectorStroke(color: color, width: width),
      );

  TypeResult<ConnectorStyle> _connectorStyle(wire.ConnectorStyle value) {
    final stroke = _stroke(value.stroke);
    final radius = expressions.decode(value.cornerRadius);
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
            ConnectorStyle(
              stroke: stroke.valueOrNull!,
              cornerRadius: radius.valueOrNull!,
              startMarker: start.valueOrNull,
              endMarker: end.valueOrNull,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<ConnectorEndpointMarker?> _endpointMarker(
    wire.ConnectorEndpointMarker? value,
  ) {
    if (value == null) return const TypeResult.success(null);
    return switch (value) {
      wire.ConnectorEndpointMarker_arrowWrapper(:final value) =>
        expressions
            .decode(value.size)
            .mapValue((size) => ConnectorEndpointMarker.arrow(size: size)),
      wire.ConnectorEndpointMarker_circleWrapper(:final value) =>
        expressions
            .decode(value.diameter)
            .mapValue(
              (diameter) => ConnectorEndpointMarker.circle(diameter: diameter),
            ),
      wire.ConnectorEndpointMarker_unknown() => invalidWire(
        "Unknown connector endpoint marker",
      ),
    };
  }

  TypeResult<List<ConnectionMarker>> _markers(
    Iterable<wire.ConnectionMarker> values,
  ) {
    final markers = <ConnectionMarker>[];
    final diagnostics = <TypeDiagnostic>[];
    for (final value in values) {
      final position = expressions.decode(value.position);
      final align = expressions.decode(value.alignToPath);
      final scope = value.scope._decode;
      diagnostics
        ..addAll(position.diagnostics)
        ..addAll(align.diagnostics);
      if (scope == null) {
        diagnostics.add(wireDiagnostic("Unknown marker scope"));
      }
      if (position.valueOrNull case final positionValue?) {
        if (align.valueOrNull case final alignValue? when scope != null) {
          markers.add(
            ConnectionMarker(
              node: decodeNode(value.node),
              position: positionValue,
              alignToPath: alignValue,
              scope: scope,
            ),
          );
        }
      }
    }
    return diagnostics.isEmpty
        ? TypeResult.success(markers)
        : TypeResult.failure(diagnostics);
  }

  TypeResult<ConnectionPath> _path(wire.ConnectionPath value) =>
      switch (value) {
        wire.ConnectionPath.straight => const TypeResult.success(
          ConnectionPath.straight(),
        ),
        wire.ConnectionPath_orthogonalWrapper(:final value) =>
          expressions
              .decode(value.bendPosition)
              .mapValue(
                (bend) => ConnectionPath.orthogonal(
                  OrthogonalConnectionPath(bendPosition: bend),
                ),
              ),
        wire.ConnectionPath_curvedWrapper(:final value) => combineResults(
          _offset(value.sourceControlOffset),
          _offset(value.targetControlOffset),
          (source, target) => ConnectionPath.curved(
            CurvedConnectionPath(
              sourceControlOffset: source,
              targetControlOffset: target,
            ),
          ),
        ),
        wire.ConnectionPath_unknown() => invalidWire("Unknown connection path"),
      };

  TypeResult<ConnectionBundlePath> _bundlePath(
    wire.ConnectionBundlePath value,
  ) => switch (value) {
    wire.ConnectionBundlePath.fan => const TypeResult.success(
      ConnectionBundlePath.fan(),
    ),
    wire.ConnectionBundlePath_orthogonalWrapper(:final value) =>
      _orthogonalBundlePath(value),
    wire.ConnectionBundlePath_unknown() => invalidWire(
      "Unknown connection bundle path",
    ),
  };

  TypeResult<ConnectionBundlePath> _orthogonalBundlePath(
    wire.OrthogonalConnectionBundlePath value,
  ) {
    final axis = value.axis._decode;
    if (axis == null) return invalidWire("Unknown connection axis");
    return expressions
        .decode(value.bendPosition)
        .mapValue(
          (bend) => ConnectionBundlePath.orthogonal(
            OrthogonalConnectionBundlePath(axis: axis, bendPosition: bend),
          ),
        );
  }
}

extension on wire.ConnectionAxis {
  ConnectionAxis? get _decode => switch (this) {
    wire.ConnectionAxis.horizontal => ConnectionAxis.horizontal,
    wire.ConnectionAxis.vertical => ConnectionAxis.vertical,
    _ => null,
  };
}

extension on wire.PresentationAnchorAlignment {
  PresentationAnchorAlignment? get _decode => switch (this) {
    wire.PresentationAnchorAlignment.topStart =>
      PresentationAnchorAlignment.topStart,
    wire.PresentationAnchorAlignment.topCenter =>
      PresentationAnchorAlignment.topCenter,
    wire.PresentationAnchorAlignment.topEnd =>
      PresentationAnchorAlignment.topEnd,
    wire.PresentationAnchorAlignment.centerStart =>
      PresentationAnchorAlignment.centerStart,
    wire.PresentationAnchorAlignment.center =>
      PresentationAnchorAlignment.center,
    wire.PresentationAnchorAlignment.centerEnd =>
      PresentationAnchorAlignment.centerEnd,
    wire.PresentationAnchorAlignment.bottomStart =>
      PresentationAnchorAlignment.bottomStart,
    wire.PresentationAnchorAlignment.bottomCenter =>
      PresentationAnchorAlignment.bottomCenter,
    wire.PresentationAnchorAlignment.bottomEnd =>
      PresentationAnchorAlignment.bottomEnd,
    _ => null,
  };
}

extension on wire.ConnectionExpressionScope {
  ConnectionExpressionScope? get _decode => switch (this) {
    wire.ConnectionExpressionScope.layer => ConnectionExpressionScope.layer,
    wire.ConnectionExpressionScope.source => ConnectionExpressionScope.source,
    wire.ConnectionExpressionScope.target => ConnectionExpressionScope.target,
    _ => null,
  };
}
