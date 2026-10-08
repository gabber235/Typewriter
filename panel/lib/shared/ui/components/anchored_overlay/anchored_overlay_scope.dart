import "package:typewriter_panel/typewriter_panel.dart";

/// Establishes a layout boundary that anchored overlays can use for placement.
///
/// The scope measures its child in the overlay's coordinate space. An overlay
/// with [BoundaryMode.nearestScope] uses the closest scope and falls back to
/// the full overlay when no scope is available.
class AnchoredOverlayScope extends StatefulWidget {
  const AnchoredOverlayScope({required this.child, super.key});

  final Widget child;

  /// Returns this scope's bounds in [overlayBox] coordinates, when laid out.
  ///
  /// Returns null before either render object has a usable size.
  static Rect? maybeScopeBoundsInOverlay(
    BuildContext context, {
    required RenderBox overlayBox,
  }) {
    final inherited = context
        .dependOnInheritedWidgetOfExactType<_AnchoredOverlayScopeMarker>();
    final scopeRenderObject = inherited?.scopeKey.currentContext
        ?.findRenderObject();
    if (scopeRenderObject is! RenderBox || !scopeRenderObject.hasSize) {
      return null;
    }

    final topLeftGlobal = scopeRenderObject.localToGlobal(Offset.zero);
    final topLeftOverlay = overlayBox.globalToLocal(topLeftGlobal);
    return topLeftOverlay & scopeRenderObject.size;
  }

  @override
  State<AnchoredOverlayScope> createState() => _AnchoredOverlayScopeState();
}

class _AnchoredOverlayScopeState extends State<AnchoredOverlayScope> {
  final GlobalKey _scopeKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return _AnchoredOverlayScopeMarker(
      scopeKey: _scopeKey,
      child: KeyedSubtree(key: _scopeKey, child: widget.child),
    );
  }
}

class _AnchoredOverlayScopeMarker extends InheritedWidget {
  const _AnchoredOverlayScopeMarker({
    required this.scopeKey,
    required super.child,
  });

  final GlobalKey scopeKey;

  @override
  bool updateShouldNotify(covariant _AnchoredOverlayScopeMarker oldWidget) {
    return scopeKey != oldWidget.scopeKey;
  }
}
