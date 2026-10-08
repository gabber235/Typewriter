import "package:typewriter_panel/typewriter_panel.dart";

part "authentication_route_access.freezed.dart";

/// Authentication outcomes understood by the router guards.
@freezed
sealed class RouteAuthenticationDecision with _$RouteAuthenticationDecision {
  const factory RouteAuthenticationDecision.loading() =
      RouteAuthenticationLoading;
  const factory RouteAuthenticationDecision.authenticated() =
      RouteAuthenticationAuthenticated;
  const factory RouteAuthenticationDecision.unauthenticated() =
      RouteAuthenticationUnauthenticated;
  const factory RouteAuthenticationDecision.unavailable() =
      RouteAuthenticationUnavailable;
}

/// Owns the authentication decision consumed by route guards.
///
/// The module starts loading, becomes ready after the binding supplies an
/// outcome, and becomes unavailable during disposal. Stable outcome changes
/// trigger router reevaluation through [reevaluation].
final class AuthenticationRouteAccess implements RouteAccessModule {
  AuthenticationRouteAccess()
    : _state = RouteAccessStateController(
        initialState: const RouteAuthenticationDecision.loading(),
        isPending: (state) => state is RouteAuthenticationLoading,
        stableStateOf: (state) => switch (state) {
          RouteAuthenticationLoading() => null,
          _ => state,
        },
      );

  final RouteAccessStateController<
    RouteAuthenticationDecision,
    RouteAuthenticationDecision
  >
  _state;
  bool _disposed = false;

  RouteAuthenticationDecision get decision => _state.current;

  /// Publishes the latest authentication outcome from the binding layer.
  void setDecision(RouteAuthenticationDecision decision) =>
      _state.transitionTo(decision);

  @override
  Listenable get reevaluation => _state.reevaluation;

  @override
  Future<void> waitUntilReady() => _state.waitUntilReady();

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _state
      ..transitionTo(const RouteAuthenticationDecision.unavailable())
      ..dispose();
  }
}
