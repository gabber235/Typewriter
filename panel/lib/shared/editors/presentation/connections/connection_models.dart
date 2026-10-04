part of "portable_connections.dart";

/// Paint ready stroke and style produced by connection resolution.
///
/// Paths are already in the layer surface's coordinate space. Keeping this
/// value separate from the declarative connection prevents the painter from
/// evaluating expressions or deciding failure policy.
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

/// A marker node positioned in layer coordinates for the overlay pass.
///
/// [identity] is occurrence based, not configuration based. Equal marker
/// declarations therefore retain separate render objects and lifecycle when
/// they occur more than once in a layer.
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
  final PortablePresentationScope scope;
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

/// Complete result of resolving one connection layer for one paint pass.
///
/// The result keeps successful geometry alongside diagnostics. Callers can
/// paint valid connections and surface invalid declarations without replacing
/// the presentation content with an error widget.
final class _ConnectionResolution {
  const _ConnectionResolution({
    required this.strokes,
    required this.markers,
    required this.diagnostics,
  });

  final List<_ResolvedStrokePath> strokes;
  final List<_ResolvedMarker> markers;
  final List<String> diagnostics;
}

/// Widget facing subset of a connection resolution.
///
/// Stroke paths stay in the render layer. Only marker configurations and
/// diagnostics cross back to the stateful widget because those two outputs
/// require widget tree participation.
final class _ConnectionOverlay {
  const _ConnectionOverlay({required this.markers, required this.diagnostics});

  const _ConnectionOverlay.empty() : markers = const [], diagnostics = const [];

  final List<_ResolvedMarker> markers;
  final List<String> diagnostics;

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
