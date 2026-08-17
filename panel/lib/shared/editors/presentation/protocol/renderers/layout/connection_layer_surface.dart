part of "../../layout_renderer.dart";

final class _ConnectionLayerSurface extends StatefulWidget {
  const _ConnectionLayerSurface({
    required this.connections,
    required this.scope,
    required this.child,
  });

  final List<PresentationConnection> connections;
  final PresentationRenderScope scope;
  final Widget child;

  @override
  State<_ConnectionLayerSurface> createState() =>
      _ConnectionLayerSurfaceState();
}

final class _ConnectionLayerSurfaceState
    extends State<_ConnectionLayerSurface> {
  _ConnectionOverlay _overlay = const _ConnectionOverlay.empty();
  _ConnectionOverlay? _pendingOverlay;
  bool _updateScheduled = false;

  void _handleOverlay(_ConnectionOverlay overlay) {
    if (_overlay == overlay || _pendingOverlay == overlay) return;
    _pendingOverlay = overlay;
    if (_updateScheduled) return;
    _updateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScheduled = false;
      final pending = _pendingOverlay;
      _pendingOverlay = null;
      if (!mounted || pending == null || pending == _overlay) return;
      setState(() => _overlay = pending);
    });
  }

  @override
  Widget build(BuildContext context) => _ConnectionLayerRenderSurface(
    connections: widget.connections,
    scope: widget.scope,
    textDirection: Directionality.of(context),
    onOverlayChanged: _handleOverlay,
    child: Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        const Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(child: _ConnectionStrokeSurface()),
          ),
        ),
        for (final marker in _overlay.markers)
          Positioned(
            left: 0,
            top: 0,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: _ConnectionMarkerBoundary(
                  identity: marker.identity,
                  child: PresentationNodeRenderer(
                    key: ValueKey(marker.identity),
                    node: marker.node,
                    scope: marker.scope,
                  ),
                ),
              ),
            ),
          ),
        widget.child,
        if (_overlay.diagnostics.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: presentationDiagnostic(context, _overlay.diagnostics),
          ),
      ],
    ),
  );
}

final class _ConnectionLayerRenderSurface
    extends SingleChildRenderObjectWidget {
  const _ConnectionLayerRenderSurface({
    required this.connections,
    required this.scope,
    required this.textDirection,
    required this.onOverlayChanged,
    required super.child,
  });

  final List<PresentationConnection> connections;
  final PresentationRenderScope scope;
  final TextDirection textDirection;
  final ValueChanged<_ConnectionOverlay> onOverlayChanged;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderConnectionLayerSurface(
        connections: connections,
        scope: scope,
        textDirection: textDirection,
        onOverlayChanged: onOverlayChanged,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderConnectionLayerSurface renderObject,
  ) {
    renderObject.update(
      connections: connections,
      scope: scope,
      textDirection: textDirection,
      onOverlayChanged: onOverlayChanged,
    );
  }
}

final class _RenderConnectionLayerSurface extends RenderProxyBox {
  _RenderConnectionLayerSurface({
    required List<PresentationConnection> connections,
    required PresentationRenderScope scope,
    required TextDirection textDirection,
    required ValueChanged<_ConnectionOverlay> onOverlayChanged,
  }) : _connections = connections,
       _scope = scope,
       _textDirection = textDirection,
       _onOverlayChanged = onOverlayChanged;

  List<PresentationConnection> _connections;
  PresentationRenderScope _scope;
  TextDirection _textDirection;
  ValueChanged<_ConnectionOverlay> _onOverlayChanged;
  _ConnectionResolution _lastResolution = const _ConnectionResolution(
    strokes: [],
    markers: [],
    diagnostics: [],
  );

  _ConnectionResolution get debugResolution => _lastResolution;

  void update({
    required List<PresentationConnection> connections,
    required PresentationRenderScope scope,
    required TextDirection textDirection,
    required ValueChanged<_ConnectionOverlay> onOverlayChanged,
  }) {
    _connections = connections;
    _scope = scope;
    _textDirection = textDirection;
    _onOverlayChanged = onOverlayChanged;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final anchors = _collectAnchors();
    final resolution = _resolveConnections(
      connections: _connections,
      scope: _scope,
      textDirection: _textDirection,
      localAnchors: anchors.local,
      exportedAnchors: anchors.exported,
    );
    _lastResolution = resolution;
    _collectStrokeSurface()?.strokes = resolution.strokes;
    final markerSurfaces = _collectMarkerSurfaces();
    for (final surface in markerSurfaces.values) {
      surface.hide();
    }
    for (final marker in resolution.markers) {
      markerSurfaces[marker.identity]?.place(marker.position, marker.angle);
    }
    _onOverlayChanged(
      _ConnectionOverlay(
        markers: resolution.markers,
        diagnostics: resolution.diagnostics,
      ),
    );
    super.paint(context, offset);
  }

  _CollectedAnchors _collectAnchors() {
    final local = <_AnchorSnapshot>[];
    final exported = <_AnchorSnapshot>[];
    final child = this.child;
    if (child != null && paintsChild(child)) {
      _visitForLayer(child, local: local, exported: exported);
    }
    return _CollectedAnchors(local: local, exported: exported);
  }

  Map<Object, _RenderConnectionMarkerBoundary> _collectMarkerSurfaces() {
    final surfaces = <Object, _RenderConnectionMarkerBoundary>{};
    final child = this.child;
    if (child != null) _visitMarkerSurfaces(child, surfaces);
    return surfaces;
  }

  _RenderConnectionStrokeSurface? _collectStrokeSurface() {
    _RenderConnectionStrokeSurface? result;
    final child = this.child;
    if (child == null) return null;
    void visit(RenderObject object) {
      if (object is _RenderConnectionLayerSurface) return;
      if (object is _RenderConnectionStrokeSurface) {
        result = object;
        return;
      }
      object.visitChildren(visit);
    }

    visit(child);
    return result;
  }

  void _visitMarkerSurfaces(
    RenderObject object,
    Map<Object, _RenderConnectionMarkerBoundary> output,
  ) {
    if (object is _RenderConnectionLayerSurface) return;
    if (object is _RenderConnectionMarkerBoundary) {
      output[object.identity] = object;
      return;
    }
    object.visitChildren((child) => _visitMarkerSurfaces(child, output));
  }

  List<_AnchorSnapshot> _collectLocalExports(RenderObject targetLayer) {
    final exported = <_AnchorSnapshot>[];
    final child = this.child;
    if (child != null && paintsChild(child)) {
      _visitLocalExports(child, targetLayer, exported);
    }
    return exported;
  }

  void _visitForLayer(
    RenderObject object, {
    required List<_AnchorSnapshot> local,
    required List<_AnchorSnapshot> exported,
  }) {
    if (object is _RenderConnectionMarkerBoundary) return;
    if (object is _RenderConnectionLayerSurface) {
      exported.addAll(object._collectLocalExports(this));
      return;
    }
    if (object is _RenderAnchorSurface) {
      local.addAll(object.snapshotsFor(this, exportedOnly: false));
    }
    object.visitChildren((child) {
      if (object.paintsChild(child)) {
        _visitForLayer(child, local: local, exported: exported);
      }
    });
  }

  void _visitLocalExports(
    RenderObject object,
    RenderObject targetLayer,
    List<_AnchorSnapshot> output,
  ) {
    if (object is _RenderConnectionMarkerBoundary ||
        object is _RenderConnectionLayerSurface) {
      return;
    }
    if (object is _RenderAnchorSurface) {
      output.addAll(object.snapshotsFor(targetLayer, exportedOnly: true));
    }
    object.visitChildren((child) {
      if (object.paintsChild(child)) {
        _visitLocalExports(child, targetLayer, output);
      }
    });
  }
}

final class _CollectedAnchors {
  const _CollectedAnchors({required this.local, required this.exported});

  final List<_AnchorSnapshot> local;
  final List<_AnchorSnapshot> exported;
}
