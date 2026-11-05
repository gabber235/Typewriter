import "package:typewriter_panel/typewriter_panel.dart";

/// Keeps keyboard focus inside an open popup.
///
/// While [active], focus that moves anywhere other than inside [child] or
/// above it comes back to the control inside [child] that last held it.
/// Above means a route opened on top of the popup, such as a dialog it
/// opened; focus moving there is left alone. Everything else counts as
/// behind the popup: the page it covers, and a route that page pushes or a
/// navigator it builds while the popup is open, both of which would
/// otherwise request focus for themselves.
///
/// The popup releases focus by closing: once it is gone or inactive, the
/// hold does nothing, so closing restores focus the way the popup does.
class PopupFocusHold extends StatefulWidget {
  const PopupFocusHold({required this.child, this.active = true, super.key});

  final bool active;
  final Widget child;

  @override
  State<PopupFocusHold> createState() => _PopupFocusHoldState();
}

class _PopupFocusHoldState extends State<PopupFocusHold> {
  final _inside = FocusNode(
    debugLabel: "Popup focus hold",
    canRequestFocus: false,
    skipTraversal: true,
  );
  FocusNode? _last;
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_focusChanged);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_focusChanged);
    _inside.dispose();
    super.dispose();
  }

  void _focusChanged() {
    if (!mounted || !widget.active) return;
    final focused = FocusManager.instance.primaryFocus;
    if (focused == null) return;
    if (_inside.hasFocus) {
      _last = focused;
      return;
    }
    if (_isAbove(focused) || _restoring) return;
    // Restores after the frame, so a popup closing in this frame has gone
    // and keeps the focus its closing gave back.
    _restoring = true;
    WidgetsBinding.instance
      ..addPostFrameCallback((_) => _restore())
      ..scheduleFrame();
  }

  void _restore() {
    _restoring = false;
    if (!mounted || !widget.active || _inside.hasFocus) return;
    final focused = FocusManager.instance.primaryFocus;
    if (focused != null && _isAbove(focused)) return;
    final last = _last;
    if (last != null && last.context != null && last.canRequestFocus) {
      last.requestFocus();
    } else {
      _inside.descendants
          .firstWhereOrNull((node) => node.canRequestFocus)
          ?.requestFocus();
    }
  }

  /// Whether [focused] sits in a route above the popup: one that, in a
  /// navigator holding the popup, is current while the route there holding
  /// the popup is not itself the route [focused] is in.
  bool _isAbove(FocusNode focused) {
    final popupRoutes = _routesHolding(context);
    final focusedContext = focused.context;
    if (focusedContext == null || popupRoutes.isEmpty) return true;
    for (final route in _routesHolding(focusedContext)) {
      final popupRoute = popupRoutes.firstWhereOrNull(
        (candidate) => identical(candidate.navigator, route.navigator),
      );
      if (popupRoute == null) continue;
      return !identical(route, popupRoute) && route.isCurrent;
    }
    return true;
  }

  /// The route [context] is in, then the route holding that route's
  /// navigator, and so on out to the root navigator.
  static List<ModalRoute<dynamic>> _routesHolding(BuildContext context) {
    final routes = <ModalRoute<dynamic>>[];
    for (
      var route = ModalRoute.of(context);
      route != null;
      route = switch (route.navigator?.context) {
        final host? => ModalRoute.of(host),
        null => null,
      }
    ) {
      routes.add(route);
    }
    return routes;
  }

  @override
  Widget build(BuildContext context) =>
      Focus(focusNode: _inside, includeSemantics: false, child: widget.child);
}
