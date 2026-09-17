import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/app/application/router/access/access.dart";
import "package:typewriter_panel/features/auth/application/application.dart";

/// Mirrors authentication provider state into the router access module.
///
/// The subscription fires immediately, then updates the module whenever the
/// authentication provider changes. Loading and provider errors become route
/// decisions instead of leaking provider details into router guards.
ProviderSubscription<AsyncValue<bool>> bindAuthenticationRouteAccess(
  WidgetRef ref,
  AuthenticationRouteAccess access,
) => ref.listenManual(
  isAuthenticatedProvider,
  (_, next) => access.setDecision(authenticationRouteDecision(next)),
  fireImmediately: true,
);

/// Converts authentication observation into the router's stable decision
/// vocabulary. Loading and errors take precedence over retained provider data.
RouteAuthenticationDecision authenticationRouteDecision(
  AsyncValue<bool> value,
) {
  if (value.isLoading) return const RouteAuthenticationDecision.loading();
  if (value.hasError) return const RouteAuthenticationDecision.unavailable();
  return value.requireValue
      ? const RouteAuthenticationDecision.authenticated()
      : const RouteAuthenticationDecision.unauthenticated();
}
