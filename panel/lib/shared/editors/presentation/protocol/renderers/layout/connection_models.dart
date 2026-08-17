part of "../../layout_renderer.dart";

final class _ResolvedStrokePath {
  const _ResolvedStrokePath({required this.path, required this.style});

  final Path path;
  final _ResolvedConnectorStyle style;

  Color get color => style.color;
  double get width => style.width;
}

final class _ResolvedConnectorStyle {
  const _ResolvedConnectorStyle({
    required this.color,
    required this.width,
    required this.cornerRadius,
    this.startMarker,
    this.endMarker,
  });

  final Color color;
  final double width;
  final double cornerRadius;
  final _ResolvedEndpointMarker? startMarker;
  final _ResolvedEndpointMarker? endMarker;
}

enum _ResolvedEndpointMarkerKind { arrow, circle }

final class _ResolvedEndpointMarker {
  const _ResolvedEndpointMarker({required this.kind, required this.extent});

  final _ResolvedEndpointMarkerKind kind;
  final double extent;

  double get inwardExtent => switch (kind) {
    _ResolvedEndpointMarkerKind.arrow => extent,
    _ResolvedEndpointMarkerKind.circle => extent / 2,
  };

  double get crossAxisExtent => extent / 2;
}

final class _ResolvedMarker {
  const _ResolvedMarker({
    required this.identity,
    required this.node,
    required this.scope,
    required this.position,
    required this.angle,
  });

  final Object identity;
  final PresentationNode node;
  final PresentationRenderScope scope;
  final Offset position;
  final double angle;

  @override
  bool operator ==(Object other) =>
      other is _ResolvedMarker &&
      other.identity == identity &&
      other.node == node &&
      other.scope == scope &&
      other.position == position &&
      other.angle == angle;

  @override
  int get hashCode => Object.hash(identity, node, scope, position, angle);
}

final class _ConnectionResolution {
  const _ConnectionResolution({
    required this.strokes,
    required this.markers,
    required this.diagnostics,
  });

  final List<_ResolvedStrokePath> strokes;
  final List<_ResolvedMarker> markers;
  final List<TypeDiagnostic> diagnostics;
}

final class _ConnectionOverlay {
  const _ConnectionOverlay({required this.markers, required this.diagnostics});

  const _ConnectionOverlay.empty() : markers = const [], diagnostics = const [];

  final List<_ResolvedMarker> markers;
  final List<TypeDiagnostic> diagnostics;

  @override
  bool operator ==(Object other) =>
      other is _ConnectionOverlay &&
      _sameMarkerConfigurations(other.markers, markers) &&
      listEquals(other.diagnostics, diagnostics);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(
      markers.map((marker) => (marker.identity, marker.node, marker.scope)),
    ),
    Object.hashAll(diagnostics),
  );
}

bool _sameMarkerConfigurations(
  List<_ResolvedMarker> left,
  List<_ResolvedMarker> right,
) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index].identity != right[index].identity ||
        left[index].node != right[index].node ||
        left[index].scope != right[index].scope) {
      return false;
    }
  }
  return true;
}
