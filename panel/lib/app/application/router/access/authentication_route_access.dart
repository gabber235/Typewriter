import "package:flutter/foundation.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/app/application/router/access/route_access_module.dart";
import "package:typewriter_panel/app/application/router/access/route_access_state_controller.dart";

part "authentication_route_access.freezed.dart";

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
