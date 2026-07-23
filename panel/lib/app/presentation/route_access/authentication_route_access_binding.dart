import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/app/application/router/access/authentication_route_access.dart";
import "package:typewriter_panel/features/auth/application/auth.dart";

ProviderSubscription<AsyncValue<bool>> bindAuthenticationRouteAccess(
  WidgetRef ref,
  AuthenticationRouteAccess access,
) => ref.listenManual(
  isAuthenticatedProvider,
  (_, next) => access.setDecision(authenticationRouteDecision(next)),
  fireImmediately: true,
);

RouteAuthenticationDecision authenticationRouteDecision(
  AsyncValue<bool> value,
) {
  if (value.isLoading) return const RouteAuthenticationDecision.loading();
  if (value.hasError) return const RouteAuthenticationDecision.unavailable();
  return value.requireValue
      ? const RouteAuthenticationDecision.authenticated()
      : const RouteAuthenticationDecision.unauthenticated();
}
