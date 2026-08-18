part of "../../layout_renderer.dart";

final class _AnchorSnapshot {
  const _AnchorSnapshot({
    required this.id,
    required this.groupIds,
    required this.position,
    required this.scope,
    required this.occurrenceIdentity,
    required this.exportToParent,
  });

  final String id;
  final List<String> groupIds;
  final Offset position;
  final PresentationRenderScope scope;
  final Object? occurrenceIdentity;
  final bool exportToParent;
}

final class _PresentationAnchorSurface extends SingleChildRenderObjectWidget {
  const _PresentationAnchorSurface({
    required this.points,
    required this.scope,
    required this.occurrenceIdentity,
    required super.child,
  });

  final List<_ResolvedAnchorPoint> points;
  final PresentationRenderScope scope;
  final Object? occurrenceIdentity;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderAnchorSurface(
    points: points,
    scope: scope,
    occurrenceIdentity: occurrenceIdentity,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderAnchorSurface renderObject,
  ) {
    renderObject.update(
      points: points,
      scope: scope,
      occurrenceIdentity: occurrenceIdentity,
      textDirection: Directionality.of(context),
    );
  }
}

final class _RenderAnchorSurface extends RenderProxyBox {
  _RenderAnchorSurface({
    required List<_ResolvedAnchorPoint> points,
    required PresentationRenderScope scope,
    required Object? occurrenceIdentity,
    required TextDirection textDirection,
  }) : _points = points,
       _scope = scope,
       _occurrenceIdentity = occurrenceIdentity,
       _textDirection = textDirection;

  List<_ResolvedAnchorPoint> _points;
  PresentationRenderScope _scope;
  Object? _occurrenceIdentity;
  TextDirection _textDirection;

  void update({
    required List<_ResolvedAnchorPoint> points,
    required PresentationRenderScope scope,
    required Object? occurrenceIdentity,
    required TextDirection textDirection,
  }) {
    if (identical(_points, points) &&
        _scope == scope &&
        _occurrenceIdentity == occurrenceIdentity &&
        _textDirection == textDirection) {
      return;
    }
    _points = points;
    _scope = scope;
    _occurrenceIdentity = occurrenceIdentity;
    _textDirection = textDirection;
    markNeedsPaint();
  }

  Iterable<_AnchorSnapshot> snapshotsFor(
    RenderObject layer, {
    required bool exportedOnly,
  }) sync* {
    final transform = getTransformTo(layer);
    for (final point in _points) {
      if (!point.visible || exportedOnly && !point.exportToParent) continue;
      yield _AnchorSnapshot(
        id: point.id,
        groupIds: point.groupIds,
        position: MatrixUtils.transformPoint(
          transform,
          point.position(size, _textDirection),
        ),
        scope: _scope,
        occurrenceIdentity: _occurrenceIdentity,
        exportToParent: point.exportToParent,
      );
    }
  }
}

final class _ConnectionMarkerBoundary extends SingleChildRenderObjectWidget {
  const _ConnectionMarkerBoundary({
    required this.identity,
    required super.child,
  });

  final Object identity;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderConnectionMarkerBoundary(identity);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderConnectionMarkerBoundary renderObject,
  ) {
    renderObject.identity = identity;
  }
}

final class _RenderConnectionMarkerBoundary extends RenderProxyBox {
  _RenderConnectionMarkerBoundary(this._identity);

  Object _identity;
  bool _visible = false;
  Offset _position = Offset.zero;
  double _angle = 0;
  final LayerHandle<TransformLayer> _transformLayer =
      LayerHandle<TransformLayer>();

  Object get identity => _identity;

  set identity(Object value) {
    if (_identity == value) return;
    _identity = value;
    markNeedsPaint();
  }

  void hide() {
    _visible = false;
  }

  void place(Offset position, double angle) {
    _visible = true;
    _position = position;
    _angle = angle;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_visible || child == null) {
      _transformLayer.layer = null;
      return;
    }
    final transform = Matrix4.identity()
      ..translateByDouble(_position.dx, _position.dy, 0, 1)
      ..rotateZ(_angle)
      ..translateByDouble(-size.width / 2, -size.height / 2, 0, 1);
    _transformLayer.layer = context.pushTransform(
      needsCompositing,
      offset,
      transform,
      super.paint,
      oldLayer: _transformLayer.layer,
    );
  }

  @override
  void dispose() {
    _transformLayer.layer = null;
    super.dispose();
  }
}

final class _ConnectionStrokeSurface extends LeafRenderObjectWidget {
  const _ConnectionStrokeSurface();

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderConnectionStrokeSurface();
}

final class _RenderConnectionStrokeSurface extends RenderBox {
  List<_ResolvedStrokePath> strokes = const [];

  @override
  void performLayout() {
    size = constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas
      ..save()
      ..translate(offset.dx, offset.dy);
    _paintResolvedConnectorPaths(canvas, strokes);
    canvas.restore();
  }
}
