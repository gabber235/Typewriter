import "package:typewriter_panel/typewriter_panel.dart";

part "route_settling.g.dart";

/// Tells when a navigation finished showing its pages in every navigator of
/// the panel.
///
/// A shown page takes keyboard focus for itself: the navigator focuses the new
/// route, and the route hands focus to its own scope when its transition
/// settles. Work that moves focus somewhere else after a navigation, such as
/// revealing a field in the side inspector, waits for [settled] so the page
/// does not take focus back afterwards.
///
/// The app registers one [RouteSettlingObserver] per navigator, nested ones
/// included.
final class RouteSettling {
  RouteSettling(this._router);

  final RoutingController _router;
  final _showing = <Route<dynamic>>{};
  var _changes = 0;
  final _waiting = <Completer<void>>[];

  /// The most frames [settled] waits for nested routers to apply a
  /// navigation, so a navigation that never completes cannot hold it forever.
  static const _frameLimit = 60;

  /// Completes once the navigation the router last accepted is shown: every
  /// nested router applied its part, every pushed page finished its
  /// transition, and two frames in a row ended without a navigator change.
  ///
  /// The panel's route state follows a navigation one frame after it was
  /// applied, and the shell may rebuild its navigators then, so one quiet
  /// frame is not yet proof; the second also lets the shown pages focus
  /// themselves first. Stops waiting early once [isCurrent] returns false.
  Future<void> settled({bool Function()? isCurrent}) async {
    var quiet = 0;
    for (var frame = 0; frame < _frameLimit && quiet < 2; frame++) {
      final changes = _changes;
      await WidgetsBinding.instance.endOfFrame;
      if (!(isCurrent?.call() ?? true)) return;
      if (_showing.isNotEmpty) {
        final shown = Completer<void>();
        _waiting.add(shown);
        await shown.future;
        quiet = 0;
      } else if (_applying || changes != _changes) {
        quiet = 0;
      } else {
        quiet++;
      }
    }
  }

  /// Whether a router of the active route chain still has children to apply.
  ///
  /// A navigation updating a parent route in place hands its children to the
  /// nested router, which pushes them in a later frame.
  bool get _applying {
    RoutingController? controller = _router;
    while (controller != null) {
      final route = controller.currentChild;
      if (route == null) return false;
      if (route.hasPendingChildren) return true;
      controller = controller.innerRouterOf<RoutingController>(route.name);
    }
    return false;
  }

  void _showingPushed(Route<dynamic> route) {
    _changes++;
    final animation = route is TransitionRoute ? route.animation : null;
    if (animation == null || animation.isCompleted) return;
    _showing.add(route);
    void follow(AnimationStatus status) {
      if (status.isAnimating) return;
      animation.removeStatusListener(follow);
      _shown(route);
    }

    animation.addStatusListener(follow);
  }

  void _shown(Route<dynamic> route) {
    _changes++;
    if (!_showing.remove(route) || _showing.isNotEmpty) return;
    final waiting = [..._waiting];
    _waiting.clear();
    for (final completer in waiting) {
      completer.complete();
    }
  }
}

/// Reports one navigator's changes to a [RouteSettling]; every navigator needs
/// its own observer.
final class RouteSettlingObserver extends NavigatorObserver {
  RouteSettlingObserver(this._settling);

  final RouteSettling _settling;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _settling._showingPushed(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _settling._showingPushed(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _settling._shown(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _settling._shown(route);
}

/// The panel's route settling, shared by every navigator the app builds.
@Riverpod(keepAlive: true)
RouteSettling routeSettling(Ref ref) =>
    RouteSettling(ref.watch(navigationRouterProvider));
