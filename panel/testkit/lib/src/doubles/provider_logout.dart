import "package:typewriter_panel/typewriter_panel.dart";

/// How the identity provider answers a request to end its session.
enum ProviderLogoutOutcome {
  /// The provider ends the session.
  ends,

  /// The provider fails the request, the way a cancelled browser sheet or an
  /// unreachable provider does.
  fails,

  /// The provider never answers, the way an open browser sheet does.
  hangs,
}

/// The identity provider's end session flow in a test world.
///
/// Signing out asks the provider to end its session; this double answers that
/// request with [outcome] and counts how often the panel asked.
final class FakeProviderLogout {
  /// How the provider answers every request to end its session.
  ProviderLogoutOutcome outcome = ProviderLogoutOutcome.ends;

  /// What a failing request fails with.
  final failure = StateError("The identity provider did not end the session");

  int _attempts = 0;

  /// How many times the panel asked the provider to end its session.
  int get attempts => _attempts;

  /// Answers one request to end the provider session.
  Future<void> end() {
    _attempts++;
    return switch (outcome) {
      ProviderLogoutOutcome.ends => Future.value(),
      ProviderLogoutOutcome.fails => Future.error(failure),
      ProviderLogoutOutcome.hangs => Completer<void>().future,
    };
  }
}
