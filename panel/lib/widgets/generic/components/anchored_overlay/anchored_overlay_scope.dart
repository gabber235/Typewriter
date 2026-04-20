import "package:flutter/widgets.dart";

class AnchoredOverlayScope extends StatefulWidget {
  const AnchoredOverlayScope({required this.child, super.key});

  final Widget child;

  static Rect? maybeScopeBoundsInOverlay(
    BuildContext context, {
    required RenderBox overlayBox,
  }) {
    final inherited = context.dependOnInheritedWidgetOfExactType<_AnchoredOverlayScopeMarker>();
    final scopeRenderObject = inherited?.scopeKey.currentContext?.findRenderObject();
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
      child: KeyedSubtree(
        key: _scopeKey,
        child: widget.child,
      ),
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
