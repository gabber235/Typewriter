part of "../../layout_renderer.dart";

Path? _resolvePath(
  ConnectionPath configuration,
  _LayerAnchor source,
  _LayerAnchor target,
  TextDirection textDirection,
  double cornerRadius,
  List<TypeDiagnostic> diagnostics,
) => switch (configuration) {
  StraightConnectionPath() =>
    Path()
      ..moveTo(source.position.dx, source.position.dy)
      ..lineTo(target.position.dx, target.position.dy),
  OrthogonalPath(:final path) => _orthogonalPath(
    source.position,
    target.position,
    path,
    source.snapshot.scope,
    cornerRadius,
    diagnostics,
  ),
  CurvedPath(:final path) => _curvedPath(
    source.position,
    target.position,
    path,
    source.snapshot.scope,
    textDirection,
    diagnostics,
  ),
};

Path? _orthogonalPath(
  Offset source,
  Offset target,
  OrthogonalConnectionPath configuration,
  PresentationRenderScope scope,
  double cornerRadius,
  List<TypeDiagnostic> diagnostics,
) {
  final bend = _evaluateUnit(
    configuration.bendPosition,
    scope,
    "bend position",
  );
  diagnostics.addAll(bend.diagnostics);
  if (bend.valueOrNull == null) return null;
  final vertical =
      (target.dy - source.dy).abs() >= (target.dx - source.dx).abs();
  final points = vertical
      ? [
          source,
          Offset(source.dx, _lerp(source.dy, target.dy, bend.valueOrNull!)),
          Offset(target.dx, _lerp(source.dy, target.dy, bend.valueOrNull!)),
          target,
        ]
      : [
          source,
          Offset(_lerp(source.dx, target.dx, bend.valueOrNull!), source.dy),
          Offset(_lerp(source.dx, target.dx, bend.valueOrNull!), target.dy),
          target,
        ];
  return _roundedPath(points, cornerRadius);
}

Path? _curvedPath(
  Offset source,
  Offset target,
  CurvedConnectionPath configuration,
  PresentationRenderScope scope,
  TextDirection textDirection,
  List<TypeDiagnostic> diagnostics,
) {
  final sourceOffset = configuration.sourceControlOffset._resolve(scope);
  final targetOffset = configuration.targetControlOffset._resolve(scope);
  diagnostics.addAll([
    ...sourceOffset.diagnostics,
    ...targetOffset.diagnostics,
  ]);
  if (sourceOffset.valueOrNull == null || targetOffset.valueOrNull == null) {
    return null;
  }
  final sourceControl = sourceOffset.valueOrNull!._logical(textDirection);
  final targetControl = targetOffset.valueOrNull!._logical(textDirection);
  return Path()
    ..moveTo(source.dx, source.dy)
    ..cubicTo(
      source.dx + sourceControl.dx,
      source.dy + sourceControl.dy,
      target.dx + targetControl.dx,
      target.dy + targetControl.dy,
      target.dx,
      target.dy,
    );
}

_ResolvedBundlePaths? _resolveBundlePaths(
  ConnectionBundlePath configuration,
  _LayerAnchor source,
  List<_LayerAnchor> targets,
  double trunkRadius,
  List<double> branchRadii,
  List<TypeDiagnostic> diagnostics,
) {
  if (configuration is FanBundlePath) {
    return _ResolvedBundlePaths(
      branches: [
        for (final target in targets)
          Path()
            ..moveTo(source.position.dx, source.position.dy)
            ..lineTo(target.position.dx, target.position.dy),
      ],
    );
  }
  final path = (configuration as OrthogonalBundlePath).path;
  final bend = _evaluateUnit(
    path.bendPosition,
    source.snapshot.scope,
    "bundle bend position",
  );
  diagnostics.addAll(bend.diagnostics);
  if (bend.valueOrNull == null) return null;
  final average =
      targets
          .map((target) => target.position)
          .reduce((left, right) => left + right) /
      targets.length.toDouble();
  final vertical = path.axis == ConnectionAxis.vertical;
  final trunkCoordinate = vertical
      ? _lerp(source.position.dx, average.dx, bend.valueOrNull!)
      : _lerp(source.position.dy, average.dy, bend.valueOrNull!);
  final trunkCorner = vertical
      ? Offset(trunkCoordinate, source.position.dy)
      : Offset(source.position.dx, trunkCoordinate);
  final sourceAxis = _axisCoordinate(source.position, vertical);
  final targetAxes = [
    for (final target in targets) _axisCoordinate(target.position, vertical),
  ];
  final minimumAxis = targetAxes.reduce(math.min);
  final maximumAxis = targetAxes.reduce(math.max);
  final primaryAxis = sourceAxis - minimumAxis >= maximumAxis - sourceAxis
      ? minimumAxis
      : maximumAxis;
  final secondaryAxis = primaryAxis == minimumAxis ? maximumAxis : minimumAxis;
  final hasSecondaryExtent =
      minimumAxis < sourceAxis && maximumAxis > sourceAxis;
  final trunk = _roundedPath([
    source.position,
    trunkCorner,
    _bundleAxisOffset(trunkCoordinate, primaryAxis, vertical),
  ], hasSecondaryExtent ? 0 : trunkRadius);
  if (hasSecondaryExtent) {
    final secondaryEnd = _bundleAxisOffset(
      trunkCoordinate,
      secondaryAxis,
      vertical,
    );
    trunk
      ..moveTo(trunkCorner.dx, trunkCorner.dy)
      ..lineTo(secondaryEnd.dx, secondaryEnd.dy);
  }
  return _ResolvedBundlePaths(
    trunk: trunk,
    branches: [
      for (final (index, target) in targets.indexed)
        _orthogonalBranch(
          source.position,
          target.position,
          trunkCoordinate,
          vertical,
          branchRadii[index],
        ),
    ],
  );
}

Path _orthogonalBranch(
  Offset source,
  Offset target,
  double trunkCoordinate,
  bool vertical,
  double radius,
) {
  final direction = vertical
      ? (target.dy - source.dy).sign
      : (target.dx - source.dx).sign;
  final axialDistance = _axisDistance(source, target, vertical);
  final lateralDistance = vertical
      ? (target.dx - trunkCoordinate).abs()
      : (target.dy - trunkCoordinate).abs();
  final approachDistance = math.min(
    radius,
    math.min(axialDistance, lateralDistance),
  );
  final approach = vertical
      ? Offset(trunkCoordinate, target.dy - direction * approachDistance)
      : Offset(target.dx - direction * approachDistance, trunkCoordinate);
  final corner = vertical
      ? Offset(trunkCoordinate, target.dy)
      : Offset(target.dx, trunkCoordinate);
  return _roundedPath([approach, corner, target], radius);
}

double _axisDistance(Offset source, Offset target, bool vertical) =>
    vertical ? (target.dy - source.dy).abs() : (target.dx - source.dx).abs();

double _axisCoordinate(Offset point, bool vertical) =>
    vertical ? point.dy : point.dx;

Offset _bundleAxisOffset(
  double trunkCoordinate,
  double axisCoordinate,
  bool vertical,
) => vertical
    ? Offset(trunkCoordinate, axisCoordinate)
    : Offset(axisCoordinate, trunkCoordinate);

Path _roundedPath(List<Offset> points, double radius) {
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (var index = 1; index + 1 < points.length; index++) {
    final previous = points[index - 1];
    final corner = points[index];
    final next = points[index + 1];
    final incoming = corner - previous;
    final outgoing = next - corner;
    final distance = math.min(
      radius,
      math.min(incoming.distance, outgoing.distance) / 2,
    );
    if (distance <= 0) {
      path.lineTo(corner.dx, corner.dy);
      continue;
    }
    final entry = corner - Offset.fromDirection(incoming.direction, distance);
    final exit = corner + Offset.fromDirection(outgoing.direction, distance);
    path
      ..lineTo(entry.dx, entry.dy)
      ..quadraticBezierTo(corner.dx, corner.dy, exit.dx, exit.dy);
  }
  path.lineTo(points.last.dx, points.last.dy);
  return path;
}

double _lerp(double start, double end, double fraction) =>
    start + (end - start) * fraction;

extension on Offset {
  Offset _logical(TextDirection direction) =>
      direction == TextDirection.ltr ? this : Offset(-dx, dy);
}

final class _LayerAnchor {
  const _LayerAnchor(this.snapshot);

  final _AnchorSnapshot snapshot;
  Offset get position => snapshot.position;
}

final class _ResolvedBundlePaths {
  const _ResolvedBundlePaths({required this.branches, this.trunk});

  final Path? trunk;
  final List<Path> branches;
}
