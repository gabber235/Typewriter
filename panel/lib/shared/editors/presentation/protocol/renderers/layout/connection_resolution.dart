part of "../../layout_renderer.dart";

void _resolveMarkers({
  required List<ConnectionMarker> templates,
  required Path path,
  required PresentationRenderScope layerScope,
  required _LayerAnchor source,
  required _LayerAnchor target,
  required Object identity,
  required List<_ResolvedMarker> output,
  required List<TypeDiagnostic> diagnostics,
  bool allowTargetScope = true,
}) {
  final metrics = path.computeMetrics().toList(growable: false);
  if (metrics.isEmpty) return;
  final metric = metrics.first;
  for (var index = 0; index < templates.length; index++) {
    final template = templates[index];
    if (!allowTargetScope &&
        template.scope == ConnectionExpressionScope.target) {
      diagnostics.add(
        _connectionDiagnostic("Bundle trunk markers cannot use a target scope"),
      );
      continue;
    }
    final markerScope = switch (template.scope) {
      ConnectionExpressionScope.layer => layerScope,
      ConnectionExpressionScope.source => source.snapshot.scope,
      ConnectionExpressionScope.target => target.snapshot.scope,
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
        node: template.node.localizeFailures(
          markerScope.expressions,
          registry: markerScope.registry,
          budget: markerScope.budget,
        ),
        scope: markerScope,
        position: tangent.position,
        angle: aligned.valueOrNull! ? tangent.angle : 0,
      ),
    );
  }
}

_ResolvedConnectorStyle? _resolveConnectorStyle(
  ConnectorStyle style,
  PresentationRenderScope scope,
  List<TypeDiagnostic> diagnostics,
) {
  final colorResult = scope.evaluate(style.stroke.color);
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
  diagnostics.addAll([
    ...colorResult.diagnostics,
    ...widthResult.diagnostics,
    ...radiusResult.diagnostics,
  ]);
  final colorValue = colorResult.valueOrNull;
  final color = colorValue is IntegerValue ? colorValue.colorOrNull : null;
  if (colorResult is TypeSuccess && color == null) {
    diagnostics.add(
      _connectionDiagnostic("Connector color must evaluate to a Color"),
    );
  }
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
  ConnectorEndpointMarker? marker,
  PresentationRenderScope scope,
  List<TypeDiagnostic> diagnostics,
) {
  if (marker == null) return null;
  final expression = switch (marker) {
    ArrowConnectorMarker(:final size) => size,
    CircleConnectorMarker(:final diameter) => diameter,
  };
  final extent = _evaluateNonnegative(expression, scope, "marker size");
  diagnostics.addAll(extent.diagnostics);
  if (extent.valueOrNull == null) return null;
  return _ResolvedEndpointMarker(
    kind: marker is ArrowConnectorMarker
        ? _ResolvedEndpointMarkerKind.arrow
        : _ResolvedEndpointMarkerKind.circle,
    extent: extent.valueOrNull!,
  );
}

TypeResult<bool> _evaluateBoolean(
  TypedExpression? expression,
  PresentationRenderScope scope,
  bool fallback,
) {
  if (expression == null) return TypeResult.success(fallback);
  final result = scope.evaluate(expression);
  if (result case TypeFailure(:final diagnostics)) {
    return TypeResult.failure(diagnostics);
  }
  final value = result.valueOrNull;
  return value is BooleanValue
      ? TypeResult.success(value.value)
      : TypeResult.failure([
          _connectionDiagnostic(
            "Connection condition must evaluate to boolean",
          ),
        ]);
}

TypeResult<double> _evaluateUnit(
  TypedExpression expression,
  PresentationRenderScope scope,
  String name,
) {
  final result = scope.evaluate(expression);
  if (result case TypeFailure(:final diagnostics)) {
    return TypeResult.failure(diagnostics);
  }
  final value = result.valueOrNull._connectionNumber;
  return value == null || !value.isFinite || value < 0 || value > 1
      ? TypeResult.failure([
          _connectionDiagnostic("Connection $name must be between 0 and 1"),
        ])
      : TypeResult.success(value);
}

TypeResult<double> _evaluateNonnegative(
  TypedExpression expression,
  PresentationRenderScope scope,
  String name,
) {
  final result = scope.evaluate(expression);
  if (result case TypeFailure(:final diagnostics)) {
    return TypeResult.failure(diagnostics);
  }
  final value = result.valueOrNull._connectionNumber;
  return value == null || !value.isFinite || value < 0
      ? TypeResult.failure([
          _connectionDiagnostic("Connection $name must be nonnegative"),
        ])
      : TypeResult.success(value);
}

TypeDiagnostic _connectionDiagnostic(String message) => TypeDiagnostic(
  code: TypeDiagnosticCode.invalidPresentation,
  message: message,
);
