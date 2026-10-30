import "package:typewriter_panel/typewriter_panel.dart";

/// The route guard reevaluation a test holds: each reevaluation waits until
/// the test completes it, so the test sees how many run at once.
final class HeldReevaluations {
  /// The reevaluations started, oldest first; complete one to finish it.
  final calls = <Completer<void>>[];

  /// How many reevaluations run now.
  var active = 0;

  /// The most reevaluations that ran at once.
  var maximumActive = 0;

  /// Starts a reevaluation that ends once the test completes it.
  Future<void> call() {
    active++;
    maximumActive = max(maximumActive, active);
    final call = Completer<void>();
    calls.add(call);
    return call.future.whenComplete(() => active--);
  }
}

/// Changing who is signed in, as the route guards see it.
extension AuthenticationFlip on AuthenticationRouteAccess {
  /// Signs the user out when signed in and in otherwise, so route access
  /// announces a change.
  void flip() => setDecision(
    decision is RouteAuthenticationAuthenticated
        ? const RouteAuthenticationDecision.unauthenticated()
        : const RouteAuthenticationDecision.authenticated(),
  );
}
