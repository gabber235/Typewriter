part of "portable_connections.dart";

/// Resolves marker nodes along a path using their declared binding scope.
///
/// Marker positions are normalized to the path length. A bundle trunk has no
/// target scope because it represents the shared source side; that invalid
/// combination becomes a diagnostic and the affected marker is skipped.
void _resolveMarkers({
  required List<skir.ConnectionMarker> templates,
  required Path path,
  required PortablePresentationScope layerScope,
  required _LayerAnchor source,
  required _LayerAnchor target,
  required Object identity,
  required List<_ResolvedMarker> output,
  required List<String> diagnostics,
  bool allowTargetScope = true,
}) {
  final metrics = path.computeMetrics().toList(growable: false);
  if (metrics.isEmpty) return;
  final metric = metrics.first;
  for (var index = 0; index < templates.length; index++) {
    final template = templates[index];
    if (!allowTargetScope &&
        template.scope.kind ==
            skir.ConnectionExpressionScope_kind.targetConst) {
      diagnostics.add(
        _connectionDiagnostic("Bundle trunk markers cannot use a target scope"),
      );
      continue;
    }
    final markerScope = switch (template.scope.kind) {
      skir.ConnectionExpressionScope_kind.layerConst => layerScope,
      skir.ConnectionExpressionScope_kind.sourceConst => source.snapshot.scope,
      skir.ConnectionExpressionScope_kind.targetConst => target.snapshot.scope,
      skir.ConnectionExpressionScope_kind.unknown => layerScope,
    };
    final position = _evaluateUnit(
      template.position,
      markerScope,
      "marker position",
    );

    final aligned = _evaluateBoolean(template.alignToPath, markerScope, false);

    diagnostics.addAll([...position.diagnostics, ...aligned.diagnostics]);

    if (position.valueOrNull == null || aligned.valueOrNull == null) continue;
    final tangent = metric.getTangentForOffset(
      metric.length * position.valueOrNull!,
    );

    if (tangent == null) continue;
    output.add(
      _ResolvedMarker(
        identity: (identity, index),
        node: template.node,
        scope: markerScope,
        position: tangent.position,
        angle: aligned.valueOrNull! ? tangent.angle : 0,
      ),
    );
  }
}

/// Evaluates connector appearance and rejects invalid numeric or color values.
///
/// Style resolution is performed in the selected anchor scope. Returning null
/// suppresses only the stroke that cannot be painted; accumulated diagnostics
/// remain available to the layer overlay.
_ResolvedConnectorStyle? _resolveConnectorStyle(
  PresentationColorEnvironment colors,
  skir.ConnectorStyle style,
  PortablePresentationScope scope,
  List<String> diagnostics,
) {
  Color? color;
  try {
    color = colors.resolve(style.stroke.color, scope);
  } on PresentationColorFailure catch (failure) {
    diagnostics.add(failure.message);
  }
  final widthResult = _evaluateNonnegative(
    style.stroke.width,
    scope,
    "stroke width",
  );
  final radiusResult = _evaluateNonnegative(
    style.cornerRadius,
    scope,
    "corner radius",
  );
  diagnostics.addAll([...widthResult.diagnostics, ...radiusResult.diagnostics]);

  if (color == null ||
      widthResult.valueOrNull == null ||
      radiusResult.valueOrNull == null) {
    return null;
  }
  return _ResolvedConnectorStyle(
    color: color,
    width: widthResult.valueOrNull!,
    cornerRadius: radiusResult.valueOrNull!,
    startMarker: _resolveEndpointMarker(style.startMarker, scope, diagnostics),
    endMarker: _resolveEndpointMarker(style.endMarker, scope, diagnostics),
  );
}

_ResolvedEndpointMarker? _resolveEndpointMarker(
  skir.ConnectorEndpointMarker? marker,
  PortablePresentationScope scope,
  List<String> diagnostics,
) {
  if (marker == null) return null;
  final expression = switch (marker) {
    skir.ConnectorEndpointMarker_arrowWrapper(:final value) => value.size,
    skir.ConnectorEndpointMarker_circleWrapper(:final value) => value.diameter,
    skir.ConnectorEndpointMarker_unknown() => null,
  };
  if (expression == null) {
    diagnostics.add(_connectionDiagnostic("Unknown connector marker"));
    return null;
  }
  final extent = _evaluateNonnegative(expression, scope, "marker size");
  diagnostics.addAll(extent.diagnostics);

  if (extent.valueOrNull == null) return null;
  return _ResolvedEndpointMarker(
    kind: marker is skir.ConnectorEndpointMarker_arrowWrapper
        ? _ResolvedEndpointMarkerKind.arrow
        : _ResolvedEndpointMarkerKind.circle,
    extent: extent.valueOrNull!,
  );
}

/// Evaluates an optional presentation condition with a typed fallback.
///
/// A missing condition uses [fallback]. A present expression must produce a
/// boolean, otherwise resolution fails visibly instead of treating malformed
/// authoring data as enabled or disabled by accident.
_ConnectionResult<bool> _evaluateBoolean(
  skir.ExpressionNode? expression,
  PortablePresentationScope scope,
  bool fallback,
) {
  if (expression == null) return _ConnectionResult.success(fallback);
  final result = scope.evaluate(expression);
  if (result.diagnostics.isNotEmpty) {
    return _ConnectionResult.failure(result.diagnostics);
  }
  final value = result.valueOrNull;
  return value is skir.DataValue_booleanWrapper
      ? _ConnectionResult.success(value.value)
      : _ConnectionResult.failure([
          _connectionDiagnostic(
            "Connection condition must evaluate to boolean",
          ),
        ]);
}

/// Evaluates a finite normalized value in the inclusive range from zero to one.
///
/// Connection bend and marker positions use this contract so routing and path
/// sampling cannot receive an invalid fraction.
_ConnectionResult<double> _evaluateUnit(
  skir.ExpressionNode expression,
  PortablePresentationScope scope,
  String name,
) {
  final result = scope.evaluate(expression);
  if (result.diagnostics.isNotEmpty) {
    return _ConnectionResult.failure(result.diagnostics);
  }
  final value = result.valueOrNull._connectionNumber;
  return value == null || !value.isFinite || value < 0 || value > 1
      ? _ConnectionResult.failure([
          _connectionDiagnostic("Connection $name must be between 0 and 1"),
        ])
      : _ConnectionResult.success(value);
}

/// Evaluates a finite nonnegative connection measurement.
///
/// Widths, radii, and marker extents are authoring values in logical pixels.
/// Invalid values become diagnostics rather than entering Flutter painting.
_ConnectionResult<double> _evaluateNonnegative(
  skir.ExpressionNode expression,
  PortablePresentationScope scope,
  String name,
) {
  final result = scope.evaluate(expression);
  if (result.diagnostics.isNotEmpty) {
    return _ConnectionResult.failure(result.diagnostics);
  }
  final value = result.valueOrNull._connectionNumber;
  return value == null || !value.isFinite || value < 0
      ? _ConnectionResult.failure([
          _connectionDiagnostic("Connection $name must be nonnegative"),
        ])
      : _ConnectionResult.success(value);
}

String _connectionDiagnostic(String message) => message;
