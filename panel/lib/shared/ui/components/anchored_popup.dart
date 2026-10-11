import "package:typewriter_panel/typewriter_panel.dart";

enum PopupPresentation { closed, preview, focused }

enum PopupCloseReason { dismissed, navigated, scopeChanged }

/// Controls one popup surface. Preview preserves the editor's keyboard focus.
class AnchoredPopupController extends ChangeNotifier {
  PopupPresentation _presentation = PopupPresentation.closed;
  PopupCloseReason _closeReason = PopupCloseReason.dismissed;
  PopupPresentation get presentation => _presentation;

  void preview() {
    if (_presentation == PopupPresentation.closed) {
      _set(PopupPresentation.preview);
    }
  }

  void openFocused() => _set(PopupPresentation.focused);

  void close({PopupCloseReason reason = PopupCloseReason.dismissed}) {
    _closeReason = reason;
    _set(PopupPresentation.closed);
  }

  void _set(PopupPresentation next) {
    if (_presentation == next) return;
    _presentation = next;
    notifyListeners();
  }
}

/// Owns one anchored surface through preview, focused opening, and dismissal.
///
/// Hover preview is optional. It adds no modal barrier or route history and
/// cannot receive keyboard focus. Click or controller activation promotes the
/// existing content to focused presentation, retaining its scroll and fields.
/// Dismissal restores valid prior focus. Navigation and scope changes do not.
class AnchoredPopup extends StatefulWidget {
  const AnchoredPopup({
    required this.builder,
    required this.popupBuilder,
    this.controller,
    this.previewOnHover = false,
    this.targetAnchor = Alignment.bottomLeft,
    this.popupAnchor = Alignment.topLeft,
    this.maxWidth = 420,
    this.maxHeight = 420,
    this.offset = Offset.zero,
    super.key,
  });

  final Widget Function(BuildContext context, VoidCallback show) builder;
  final Widget Function(BuildContext context, VoidCallback close) popupBuilder;
  final AnchoredPopupController? controller;
  final bool previewOnHover;
  final Alignment targetAnchor;
  final Alignment popupAnchor;
  final double maxWidth;
  final double maxHeight;
  final Offset offset;

  @override
  State<AnchoredPopup> createState() => _AnchoredPopupState();
}

class _AnchoredPopupState extends State<AnchoredPopup> {
  final _portal = OverlayPortalController();
  final _focus = FocusScopeNode(
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );
  final _entry = FocusNode(debugLabel: "Popup entry", skipTraversal: true);
  late AnchoredPopupController _controller;
  PopupPresentation _presentation = PopupPresentation.closed;
  FocusNode? _previousFocus;
  LocalHistoryEntry? _history;
  Timer? _hoverExit;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? AnchoredPopupController();
    _controller.addListener(_changed);
    if (_controller.presentation != PopupPresentation.closed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _changed();
      });
    }
  }

  @override
  void didUpdateWidget(AnchoredPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == oldWidget.controller) return;
    _controller.removeListener(_changed);
    _retire();
    if (oldWidget.controller == null) _controller.dispose();
    _controller = widget.controller ?? AnchoredPopupController();
    _controller.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _changed();
    });
  }

  void _changed() {
    _hoverExit?.cancel();
    final next = _controller.presentation;
    final before = _presentation;
    if (next == before) return;
    if (next == PopupPresentation.closed) {
      final previous = _previousFocus;
      final restore = _controller._closeReason == PopupCloseReason.dismissed;
      if (!restore && _focus.hasFocus) {
        _focus.unfocus(disposition: UnfocusDisposition.scope);
      }
      _retire();
      if (restore && previous?.context != null && previous!.canRequestFocus) {
        previous.requestFocus();
      }
      setState(() {});
      return;
    }
    _presentation = next;
    if (next == PopupPresentation.focused) {
      _previousFocus = FocusManager.instance.primaryFocus;
      final route = ModalRoute.of(context);
      if (route != null) {
        _history = LocalHistoryEntry(
          onRemove: () {
            _history = null;
            _controller.close();
          },
          impliesAppBarDismissal: false,
        );
        route.addLocalHistoryEntry(_history!);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _presentation == PopupPresentation.focused) {
          if (!_focus.hasFocus) {
            (_focus.traversalDescendants.firstOrNull ?? _entry).requestFocus();
          }
        }
      });
    }
    if (!_portal.isShowing) _portal.show();
    setState(() {});
  }

  void _retire() {
    _hoverExit?.cancel();
    _previousFocus = null;
    _presentation = PopupPresentation.closed;
    final history = _history;
    _history = null;
    history?.remove();
    if (_portal.isShowing) _portal.hide();
  }

  void _enter(PointerEnterEvent event) {
    _hoverExit?.cancel();
    if (widget.previewOnHover) _controller.preview();
  }

  void _exit(PointerExitEvent event) {
    if (_presentation != PopupPresentation.preview) return;
    _hoverExit?.cancel();
    _hoverExit = Timer(const Duration(milliseconds: 180), () {
      if (mounted && _presentation == PopupPresentation.preview) {
        _controller.close();
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    _retire();
    _controller.close(reason: PopupCloseReason.scopeChanged);
    if (widget.controller == null) _controller.dispose();
    _focus.dispose();
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => OverlayPortal.overlayChildLayoutBuilder(
    controller: _portal,
    child: MouseRegion(
      onEnter: _enter,
      onExit: _exit,
      child: widget.builder(context, _controller.openFocused),
    ),
    overlayChildBuilder: (context, info) {
      final anchor = MatrixUtils.transformRect(
        info.childPaintTransform,
        Offset.zero & info.childSize,
      );
      final color = context.theme.colorScheme.surfaceContainer;
      final focused = _presentation == PopupPresentation.focused;
      return Positioned.fill(
        child: Stack(
          children: [
            if (focused)
              ModalBarrier(
                key: const ValueKey("popup barrier"),
                onDismiss: _controller.close,
                semanticsLabel: "Dismiss popup",
              ),
            CustomSingleChildLayout(
              key: const ValueKey("popup content"),
              delegate: _PopupPosition(
                anchor: anchor,
                targetAnchor: widget.targetAnchor,
                popupAnchor: widget.popupAnchor,
                offset: widget.offset,
                maxWidth: widget.maxWidth,
                maxHeight: widget.maxHeight,
              ),
              child: MouseRegion(
                onEnter: _enter,
                onExit: _exit,
                child: Listener(
                  onPointerDown: (_) => _controller.openFocused(),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 60),
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
                              _controller.close();
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
                            canRequestFocus: focused,
                            descendantsAreFocusable: focused,
                            descendantsAreTraversable: focused,
                            autofocus: focused,
                            child: Focus(
                              focusNode: _entry,
                              child: Surface(
                                color: color,
                                foreground: context.colors.contentPrimary,
                                secondaryForeground:
                                    context.colors.contentSecondary,
                                child: Builder(
                                  builder: (context) => widget.popupBuilder(
                                    context,
                                    _controller.close,
                                  ),
                                ),
                              ),
                            ),
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
