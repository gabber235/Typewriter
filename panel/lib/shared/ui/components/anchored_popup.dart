import "package:typewriter_panel/typewriter_panel.dart";

/// Provides a transient popup anchored to caller supplied content.
///
/// The widget owns popup visibility, local route dismissal, and focus
/// restoration. The caller owns the trigger and popup content. Closing removes
/// only the local history entry, so it never pops the surrounding route. Use
/// [AnchoredOverlayPortal] instead when the overlay should not impose popup
/// focus or modal barrier behavior.
class AnchoredPopup extends StatefulWidget {
  const AnchoredPopup({
    required this.builder,
    required this.popupBuilder,
    this.targetAnchor = Alignment.bottomLeft,
    this.popupAnchor = Alignment.topLeft,
    this.maxWidth = 420,
    this.maxHeight = 420,
    this.offset = Offset.zero,
    super.key,
  });

  final Widget Function(BuildContext context, VoidCallback show) builder;
  final Widget Function(BuildContext context, VoidCallback close) popupBuilder;
  final Alignment targetAnchor;
  final Alignment popupAnchor;
  final double maxWidth;
  final double maxHeight;
  final Offset offset;

  @override
  State<AnchoredPopup> createState() => _AnchoredPopupState();
}

class _AnchoredPopupState extends State<AnchoredPopup> {
  final _controller = OverlayPortalController();
  final _focus = FocusScopeNode(
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );
  FocusNode? _previousFocus;
  LocalHistoryEntry? _history;

  void _show() {
    if (_controller.isShowing) return;
    _previousFocus = FocusManager.instance.primaryFocus;
    final route = ModalRoute.of(context);
    if (route != null) {
      _history = LocalHistoryEntry(
        onRemove: _closed,
        impliesAppBarDismissal: false,
      );
      route.addLocalHistoryEntry(_history!);
    }
    _controller.show();
  }

  void _close() {
    final history = _history;
    if (history == null) {
      _closed();
    } else {
      history.remove();
    }
  }

  void _closed() {
    _history = null;
    if (_controller.isShowing) _controller.hide();
    final previous = _previousFocus;
    _previousFocus = null;
    if (previous?.context != null) previous!.requestFocus();
  }

  @override
  void dispose() {
    _previousFocus = null;
    _history?.remove();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => OverlayPortal.overlayChildLayoutBuilder(
    controller: _controller,
    child: widget.builder(context, _show),
    overlayChildBuilder: (context, info) {
      final anchor = MatrixUtils.transformRect(
        info.childPaintTransform,
        Offset.zero & info.childSize,
      );
      final color = context.theme.colorScheme.surfaceContainer;
      return Positioned.fill(
        child: Stack(
          children: [
            ModalBarrier(onDismiss: _close, semanticsLabel: "Dismiss popup"),
            CustomSingleChildLayout(
              delegate: _PopupPosition(
                anchor: anchor,
                targetAnchor: widget.targetAnchor,
                popupAnchor: widget.popupAnchor,
                offset: widget.offset,
                maxWidth: widget.maxWidth,
                maxHeight: widget.maxHeight,
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 60),
                builder: (context, opacity, child) =>
                    Opacity(opacity: opacity, child: child),
                child: Material(
                  elevation: 4,
                  color: color,
                  shape: RoundedRectangleBorder(
                    borderRadius: context.shapes.mediumBorderRadius,
                  ),
                  child: Actions(
                    actions: {
                      DismissIntent: CallbackAction<DismissIntent>(
                        onInvoke: (_) {
                          _close();
                          return null;
                        },
                      ),
                    },
                    child: Shortcuts(
                      shortcuts: const {
                        SingleActivator(LogicalKeyboardKey.escape):
                            DismissIntent(),
                      },
                      child: FocusScope(
                        node: _focus,
                        autofocus: true,
                        child: Surface(
                          color: color,
                          foreground: context.colors.contentPrimary,
                          secondaryForeground: context.colors.contentSecondary,
                          child: Builder(
                            builder: (context) =>
                                widget.popupBuilder(context, _close),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _PopupPosition extends SingleChildLayoutDelegate {
  const _PopupPosition({
    required this.anchor,
    required this.targetAnchor,
    required this.popupAnchor,
    required this.offset,
    required this.maxWidth,
    required this.maxHeight,
  });

  final Rect anchor;
  final Alignment targetAnchor;
  final Alignment popupAnchor;
  final Offset offset;
  final double maxWidth;
  final double maxHeight;
  static const _margin = 8.0;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(
        Size(
          min(maxWidth, max(0, constraints.maxWidth - _margin * 2)),
          min(maxHeight, max(0, constraints.maxHeight - _margin * 2)),
        ),
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final position =
        targetAnchor.withinRect(anchor) +
        offset -
        popupAnchor.alongSize(childSize);
    return Offset(
      position.dx.clamp(
        _margin,
        max(_margin, size.width - childSize.width - _margin),
      ),
      position.dy.clamp(
        _margin,
        max(_margin, size.height - childSize.height - _margin),
      ),
    );
  }

  @override
  bool shouldRelayout(_PopupPosition oldDelegate) =>
      anchor != oldDelegate.anchor ||
      targetAnchor != oldDelegate.targetAnchor ||
      popupAnchor != oldDelegate.popupAnchor ||
      offset != oldDelegate.offset ||
      maxWidth != oldDelegate.maxWidth ||
      maxHeight != oldDelegate.maxHeight;
}
