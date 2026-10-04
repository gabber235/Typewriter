import "dart:math" as math;

import "package:flutter/foundation.dart" show listEquals;
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/expression.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/presentation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:typewriter_panel/typewriter_panel.dart";

part "connection_geometry.dart";
part "hierarchy_geometry.dart";
part "hierarchy_models.dart";
part "hierarchy_renderer.dart";
part "hierarchy_surface.dart";
part "connection_layer_surface.dart";
part "connection_models.dart";
part "connection_painter.dart";
part "connection_paths.dart";
part "connection_renderer.dart";
part "connection_resolution.dart";
part "connection_surface.dart";

final class _ConnectionResult<T> {
  const _ConnectionResult.success(T value)
    : valueOrNull = value,
      diagnostics = const [];

  const _ConnectionResult.failure(this.diagnostics) : valueOrNull = null;

  final T? valueOrNull;
  final List<String> diagnostics;
}

extension on PortableExpressionResult {
  types.DataValue? get valueOrNull => switch (this) {
    PortableExpressionAvailable(:final value) => value,
    PortableExpressionUnavailable() || PortableExpressionFailed() => null,
  };

  List<String> get diagnostics => switch (this) {
    PortableExpressionFailed(:final message) => [message],
    PortableExpressionUnavailable() => const [
      "A connection expression needs an unavailable value",
    ],
    PortableExpressionAvailable() => const [],
  };
}

extension on PortablePresentationScope {
  Object get connectionOccurrenceIdentity => Object.hashAll([
    resource,
    for (final entry in bindings.entries)
      if (entry.value.location case final location?)
        (entry.key, location.resource, location.path),
  ]);
}

Widget _connectionDiagnostics(List<String> diagnostics) => Builder(
  builder: (context) => Material(
    color: context.colors.surface.withValues(alpha: 0),
    child: Padding(
      padding: EdgeInsets.all(context.spacing.space2),
      child: Text(
        diagnostics.join("\n"),
        style: context.theme.textTheme.bodyMedium?.copyWith(
          color: context.colors.danger,
        ),
      ),
    ),
  ),
);
