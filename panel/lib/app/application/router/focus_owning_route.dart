part of "app_router.dart";

/// Every page of the panel: a Material page route that moves keyboard focus
/// to itself on push only while it can own focus.
RouteType get _focusOwningRouteType => RouteType.custom(
  customRouteBuilder: <T>(context, child, page) =>
      _FocusOwningPageRoute<T>(page: page),
);

/// A page that takes focus on push only when the route hosting its navigator
/// is current, and so up through every enclosing navigator.
///
/// A navigator focuses its enclosing scope when a route is pushed. A nested
/// navigator that pushes late, such as a surface whose route resolves after
/// the user opened search, would otherwise take focus from the popup or
/// dialog in front of it.
class _FocusOwningPageRoute<T> extends PageRoute<T>
    with MaterialRouteTransitionMixin<T> {
  _FocusOwningPageRoute({required AutoRoutePage<T> page})
    : super(settings: page);

  @override
  bool get requestFocus => super.requestFocus && _hostsAreCurrent;

  bool get _hostsAreCurrent {
    for (
      var host = navigator;
      host != null;
      host = host.context.findAncestorStateOfType<NavigatorState>()
    ) {
      if (ModalRoute.isCurrentOf(host.context) == false) return false;
    }
    return true;
  }

  AutoRoutePage<T> get _page => settings as AutoRoutePage<T>;

  @override
  void install() {
    super.install();
    _page.routeData.setAnimation(animation);
  }

  @override
  Widget buildContent(BuildContext context) => _page.buildPage(context);

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  bool get allowSnapshotting => _page.allowSnapshotting;

  @override
  bool get opaque => _page.opaque;

  @override
  String get debugLabel => "${super.debugLabel}(${_page.name})";
}
