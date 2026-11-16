import "package:typewriter_panel/typewriter_panel.dart";

enum PopupPresentation { closed, preview, focused }

enum PopupCloseReason { dismissed, navigated, scopeChanged }

/// Controls one popup surface. Preview preserves the editor's keyboard focus.
class AnchoredPopupController extends ChangeNotifier {
  PopupPresentation _presentation = PopupPresentation.closed;
  PopupCloseReason _closeReason = PopupCloseReason.dismissed;
  Offset? _position;
  PopupPresentation get presentation => _presentation;

  /// Whether the popup shows, previewed or focused.
  bool get isOpen => _presentation != PopupPresentation.closed;

  void preview() {
    if (_presentation == PopupPresentation.closed) {
      _set(PopupPresentation.preview);
    }
  }

  void openFocused() {
    _position = null;
    _set(PopupPresentation.focused);
  }

  /// Opens focused at [position], relative to the anchor's top left, as a
  /// pointer opened context menu does.
  void openAt(Offset position) {
    _position = position;
    if (_presentation == PopupPresentation.focused) {
      notifyListeners();
      return;
    }
    _set(PopupPresentation.focused);
  }

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
/// Hover opens a preview. It adds no modal barrier or route history and
/// cannot receive keyboard focus. Click or controller activation promotes the
/// existing content to focused presentation, retaining its scroll and fields.
/// Dismissal restores valid prior focus. Navigation and scope changes do not.
///
/// The popup sits on [RawMenuAnchor]: it grows out of its control with
/// panelIn and goes back into it with panelOut, staying shown while it
/// leaves.
class AnchoredPopup extends StatefulWidget {
  const AnchoredPopup({
    required this.builder,
    required this.popupBuilder,
    this.controller,
    this.targetAnchor = Alignment.bottomLeft,
    this.popupAnchor = Alignment.topLeft,
    this.maxWidth = 420,
    this.maxHeight = 420,
    this.offset = Offset.zero,
    this.opensOnHover = true,
    this.semanticLabel,
    this.color,
    this.shape,
    this.minWidth = 0,
    this.opener,
    super.key,
  });

  final Widget Function(BuildContext context, VoidCallback show) builder;
  final Widget Function(BuildContext context, VoidCallback close) popupBuilder;
  final AnchoredPopupController? controller;
  final Alignment targetAnchor;
  final Alignment popupAnchor;
  final double maxWidth;
  final double maxHeight;
  final double minWidth;
  final Offset offset;

  /// The control that opens the popup; dismissal returns focus to it even
  /// when a pointer opened the popup and it never held focus.
  final FocusNode? opener;

  /// What assistive technology calls the open popup, such as Context menu.
  final String? semanticLabel;

  /// The popup's fill; the raised container colour by default.
  final Color? color;

  /// The popup's outline; the medium rounded rectangle by default.
  final ShapeBorder? shape;

  /// Hovering the control opens a preview that closes after the pointer
  /// leaves, a press inside a preview focuses it, and Escape closes a
  /// preview before the focused control sees it. Off for a menu a field
  /// opens with [AnchoredPopupController.preview] while focus stays in the
  /// field, which keeps the keys.
  final bool opensOnHover;

  @override
  State<AnchoredPopup> createState() => _AnchoredPopupState();
}

class _AnchoredPopupState extends State<AnchoredPopup> {
  final _menu = MenuController();

  /// Held while panelOut plays; hides the overlay once it settles.
  VoidCallback? _hideOverlay;
  bool get _leaving => _hideOverlay != null;
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
    FocusManager.instance.addEarlyKeyEventHandler(_dismissPreview);
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
      // RawMenuAnchor answers with onCloseRequested; the overlay stays
      // while panelOut plays.
      if (_menu.isOpen) _menu.close();
      if (restore && previous?.context != null && previous!.canRequestFocus) {
        previous.requestFocus();
      }
      setState(() {});
      return;
    }
    _presentation = next;
    if (next == PopupPresentation.focused) {
      _previousFocus = widget.opener ?? FocusManager.instance.primaryFocus;
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
            // The first item, such as the first issue; Close is chrome.
            (_focus.firstItem ??
                    _focus.traversalDescendants.firstOrNull ??
                    _entry)
                .requestFocus();
          }
        }
      });
    }
    _menu.open(position: _controller._position);
    setState(() {});
  }

  void _retire() {
    _hoverExit?.cancel();
    _previousFocus = null;
    _presentation = PopupPresentation.closed;
    final history = _history;
    _history = null;
    history?.remove();
  }

  // Opening while leaving retargets the same motion from where it is.
  void _openRequested(Offset? position, VoidCallback showOverlay) {
    _hideOverlay = null;
    showOverlay();
    if (mounted) setState(() {});
  }

  void _closeRequested(VoidCallback hideOverlay) {
    // A group asks every member to close while one of them opens, this one
    // included before it shows.
    if (!mounted || !_menu.isOpen) return hideOverlay();
    _hideOverlay = hideOverlay;
    // An ancestor scroll or a parent group closes the menu directly; the
    // popup controller follows so focus restore stays one path.
    if (_controller.presentation != PopupPresentation.closed) {
      _controller.close();
    }
    setState(() {});
  }

  /// Called by [_PopupArrival] once panelOut has settled at 0.
  void _gone() {
    final hide = _hideOverlay;
    if (!mounted || hide == null) return;
    _hideOverlay = null;
    hide();
  }

  void _enter(PointerEnterEvent event) {
    if (!widget.opensOnHover) return;
    _hoverExit?.cancel();
    _controller.preview();
  }

  // Preview leaves focus outside this subtree, so its dismissal must run
  // before the editor handles Escape. Both presentations use the same intent.
  KeyEventResult _dismissPreview(KeyEvent event) {
    final popupContext = _entry.context;
    if (!widget.opensOnHover ||
        _presentation != PopupPresentation.preview ||
        popupContext == null ||
        event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape) {
      return KeyEventResult.ignored;
    }
    Actions.invoke(popupContext, const DismissIntent());
    return KeyEventResult.handled;
  }

  void _exit(PointerExitEvent event) {
    if (_presentation != PopupPresentation.preview) return;
    _hoverExit?.cancel();
    _hoverExit = Timer(context.timing.hoverExitDelay, () {
      if (mounted && _presentation == PopupPresentation.preview) {
        _controller.close();
      }
    });
  }

  @override
  void dispose() {
    FocusManager.instance.removeEarlyKeyEventHandler(_dismissPreview);
    _controller.removeListener(_changed);
    _retire();
    _hideOverlay = null;
    _controller.close(reason: PopupCloseReason.scopeChanged);
    if (widget.controller == null) _controller.dispose();
    _focus.dispose();
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawMenuAnchor(
      controller: _menu,
      consumeOutsideTaps: _presentation == PopupPresentation.focused,
      onOpenRequested: _openRequested,
      onCloseRequested: _closeRequested,
      builder: (context, menu, child) => MouseRegion(
        onEnter: _enter,
        onExit: _exit,
        child: widget.builder(context, _controller.openFocused),
      ),
      overlayBuilder: (context, info) => Positioned.fill(
        // Keeps the popup's semantics inside its own boundary.
        child: Semantics(
          container: true,
          child: Stack(
            children: [
              // Assistive technology still finds a way out without a
              // barrier; pointers pass through to the page.
              if (_presentation == PopupPresentation.focused)
                Positioned.fill(
                  child: Semantics(
                    container: true,
                    label: "Dismiss popup",
                    button: true,
                    onTap: _controller.close,
                    child: const SizedBox.expand(),
                  ),
                ),
              CustomSingleChildLayout(
                delegate: _PopupPosition(
                  anchor: info.position == null
                      ? info.anchorRect
                      : info.anchorRect.topLeft + info.position! & Size.zero,
                  targetAnchor: widget.targetAnchor,
                  popupAnchor: widget.popupAnchor,
                  offset: widget.offset,
                  maxWidth: widget.maxWidth,
                  maxHeight: widget.maxHeight,
                  minWidth: widget.minWidth,
                ),
                child: TapRegion(
                  groupId: info.tapRegionGroupId,
                  // A root RawMenuAnchor leaves outside taps to its owner.
                  onTapOutside: (_) {
                    if (_presentation == PopupPresentation.focused) {
                      _controller.close();
                    }
                  },
                  child: Semantics(
                    container: true,
                    label: widget.semanticLabel,
                    child: _content(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final color = widget.color ?? context.theme.colorScheme.surfaceContainer;
    final shape =
        widget.shape ??
        RoundedRectangleBorder(borderRadius: context.shapes.mediumBorderRadius);
    final focused = _presentation == PopupPresentation.focused;
    return MouseRegion(
      onEnter: _enter,
      onExit: _exit,
      child: IgnorePointer(
        ignoring: _leaving,
        child: Listener(
          onPointerDown: (_) {
            if (widget.opensOnHover) _controller.openFocused();
          },
          child: _PopupArrival(
            open: !_leaving,
            origin: widget.popupAnchor,
            onGone: _gone,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: color,
                shape: shape,
                shadows: context.menuShadow,
              ),
              child: ClipPath(
                clipper: ShapeBorderClipper(shape: shape),
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
                    child: PopupFocusHold(
                      active: focused,
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
      ),
    );
  }
}

/// Grows the popup out of the edge that touches its control.
class _PopupArrival extends HookWidget {
  const _PopupArrival({
    required this.open,
    required this.origin,
    required this.onGone,
    required this.child,
  });

  final bool open;
  final Alignment origin;
  final VoidCallback onGone;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final arrival = useMotion(
      open ? MotionToken.panelIn : MotionToken.panelOut,
      open ? 1.0 : 0.0,
      initial: 0.0,
    );
    final settled = arrival.settled;
    useEffect(() {
      if (!open && settled) {
        // After the frame, so hiding the overlay never happens during build.
        WidgetsBinding.instance.addPostFrameCallback((_) => onGone());
      }
      return null;
    }, [open, settled]);
    final travel = arrival.value;
    final start = context.motion.spec(MotionToken.panelIn).landing.originScale;
    return Opacity(
      opacity: travel.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: lerpDouble(start, 1, travel),
        alignment: origin,
        child: child,
      ),
    );
  }
}

class _PopupPosition extends SingleChildLayoutDelegate {
  const _PopupPosition({
    required this.anchor,
    required this.targetAnchor,
    required this.popupAnchor,
    required this.offset,
    required this.maxWidth,
    required this.maxHeight,
    required this.minWidth,
  });

  final Rect anchor;
  final Alignment targetAnchor;
  final Alignment popupAnchor;
  final Offset offset;
  final double maxWidth;
  final double maxHeight;
  final double minWidth;
  static const _margin = 8.0;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final width = min(maxWidth, max(0.0, constraints.maxWidth - _margin * 2));
    return BoxConstraints(
      minWidth: min(minWidth, width),
      maxWidth: width,
      maxHeight: min(maxHeight, max(0, constraints.maxHeight - _margin * 2)),
    );
  }

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
      maxHeight != oldDelegate.maxHeight ||
      minWidth != oldDelegate.minWidth;
}
