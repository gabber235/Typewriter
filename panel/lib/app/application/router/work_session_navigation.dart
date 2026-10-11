part of "app_router.dart";

final _workAdmissionZoneKey = Object();

/// Consent belongs to the exact matched routes of one asynchronous navigation.
final class _WorkNavigationAdmission {
  _WorkNavigationAdmission(this.source, List<RouteMatch> matches)
    : _remaining = List.of(matches);
  final LocalWorkScope source;
  final List<RouteMatch> _remaining;
  bool _closed = false;

  bool covers(List<RouteMatch> matches, LocalWorkScope current) =>
      !_closed &&
      current == source &&
      matches.length == _remaining.length &&
      Iterable.generate(matches.length)
          .every((index) => _sameRoute(matches[index], _remaining[index]));

  bool consume(RouteMatch route, LocalWorkScope current) {
    if (_closed ||
        current != source ||
        _remaining.isEmpty ||
        !_sameRoute(route, _remaining.first)) {
      return false;
    }
    _remaining.removeAt(0);
    if (_remaining.isEmpty) close();
    return true;
  }

  void close() {
    _closed = true;
    _remaining.clear();
  }

  static bool _sameRoute(RouteMatch first, RouteMatch second) =>
      first.name == second.name &&
      first.stringMatch == second.stringMatch &&
      const DeepCollectionEquality().equals(
        first.params.rawMap,
        second.params.rawMap,
      ) &&
      const DeepCollectionEquality().equals(
        first.queryParams.rawMap,
        second.queryParams.rawMap,
      );
}

final class _WorkRouteObservation {
  _WorkRouteObservation(this.path, this.matchIds);
  factory _WorkRouteObservation.capture(AppRouter router) =>
      _WorkRouteObservation(
        router.currentPath,
        router.stackData.map((route) => route.matchId).toList(),
      );
  final String path;
  final List<Object> matchIds;
  bool matches(AppRouter router) =>
      path == router.currentPath &&
      listEquals(
        matchIds,
        router.stackData.map((route) => route.matchId).toList(),
      );
}

LocalWorkScope _workDestinationScope(
  List<RouteMatch> matches,
  LocalWorkScope source,
) {
  final last = matches.last;
  for (final route in last.flattened.reversed) {
    final organization = route.params.optString("organizationId");
    if (organization != null && organization.isNotEmpty) {
      return source.copyWith(
        organizationId: skir.recordId("organization:$organization"),
      );
    }
  }
  return last.name == IndexRoute.name || last.name == AuthRoute.name
      ? source.copyWith(organizationId: null)
      : source;
}

/// Protects platform route changes before AutoRoute edits pages or URL history.
final class _WorkSessionRouterDelegate extends AutoRouterDelegate {
  _WorkSessionRouterDelegate(
    this.owner, {
    super.navRestorationScopeId,
    super.placeholder,
    super.navigatorObservers,
    super.deepLinkBuilder,
    super.rebuildStackOnDeepLink,
    super.reevaluateListenable,
    super.clipBehavior,
  }) : super(owner);
  final AppRouter owner;
  bool _closed = false;

  @override
  void dispose() {
    if (_closed) return;
    _closed = true;
    super.dispose();
  }

  @override
  Future<void> setNewRoutePath(UrlState configuration) async {
    await owner._admitNavigation(
      configuration.segments,
      () => super.setNewRoutePath(configuration),
    );
  }
}
