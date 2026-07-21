import "package:flutter/widgets.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class AnchoredOverlayPortal extends StatefulWidget {
  const AnchoredOverlayPortal({
    required this.visible,
    required this.child,
    required this.overlayBuilder,
    this.config = const AnchoredOverlayConfig(),
    super.key,
  });

  final bool visible;
  final Widget child;
  final Widget Function(BuildContext context, Size anchorSize) overlayBuilder;
  final AnchoredOverlayConfig config;

  @override
  State<AnchoredOverlayPortal> createState() => _AnchoredOverlayPortalState();
}

class _AnchoredOverlayPortalState extends State<AnchoredOverlayPortal> {
  final OverlayPortalController _controller = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncVisibility();
      }
    });
  }

  @override
  void didUpdateWidget(covariant AnchoredOverlayPortal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _syncVisibility();
        }
      });
    }
  }

  void _syncVisibility() {
    if (widget.visible && !_controller.isShowing) {
      _controller.show();
      return;
    }
    if (!widget.visible && _controller.isShowing) {
      _controller.hide();
    }
  }

  Rect _resolveBoundaryRect(BuildContext context, OverlayChildLayoutInfo info) {
    final overlayBounds = Rect.fromLTWH(
      0,
      0,
      info.overlaySize.width,
      info.overlaySize.height,
    );

    if (widget.config.boundaryMode == BoundaryMode.overlay) {
      return overlayBounds;
    }

    final overlayRenderObject = Overlay.maybeOf(
      context,
    )?.context.findRenderObject();
    if (overlayRenderObject is! RenderBox || !overlayRenderObject.hasSize) {
      return overlayBounds;
    }

    final scopeBounds = AnchoredOverlayScope.maybeScopeBoundsInOverlay(
      context,
      overlayBox: overlayRenderObject,
    );
    if (scopeBounds == null) {
      return overlayBounds;
    }

    return scopeBounds.intersect(overlayBounds);
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _controller,
      child: widget.child,
      overlayChildBuilder: (context, layoutInfo) {
        final anchorRect = MatrixUtils.transformRect(
          layoutInfo.childPaintTransform,
          Offset.zero & layoutInfo.childSize,
        );
        final boundaryRect = _resolveBoundaryRect(context, layoutInfo);

        return AnchoredOverlayPositioned(
          anchorRect: anchorRect,
          overlaySize: layoutInfo.overlaySize,
          boundaryRect: boundaryRect,
          config: widget.config,
          child: widget.overlayBuilder(context, layoutInfo.childSize),
        );
      },
    );
  }
}
