import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("SecretFieldState", () {
    test("supports value equality and copying", () {
      final expiry = DateTime.utc(2026, 8, 19, 12);
      final state = SecretFieldRevealed(value: "secret", expiresAt: expiry);

      expect(
        state,
        SecretFieldState.revealed(value: "secret", expiresAt: expiry),
      );
      expect(state.copyWith(value: "updated").value, "updated");
    });

    test("matches every state exhaustively", () {
      expect(_label(const SecretFieldState.idle()), "idle");
      expect(_label(const SecretFieldState.loading()), "loading");
      expect(
        _label(const SecretFieldState.revealed(value: "secret")),
        "revealed",
      );
      expect(
        _label(const SecretFieldState.expired(value: "secret")),
        "expired",
      );
      expect(_label(const SecretFieldState.error(message: "failure")), "error");
    });

    test("calculates remaining duration from the supplied time", () {
      final now = DateTime.utc(2026, 8, 19, 12);
      final state = SecretFieldRevealed(
        value: "secret",
        expiresAt: now.add(const Duration(seconds: 30)),
      );

      expect(state.remainingDurationAt(now), const Duration(seconds: 30));
      expect(
        state.remainingDurationAt(now.add(const Duration(seconds: 10))),
        const Duration(seconds: 20),
      );
      expect(
        state.remainingDurationAt(now.add(const Duration(seconds: 31))),
        Duration.zero,
      );
      expect(state.isExpiredAt(now), isFalse);
      expect(state.isExpiredAt(now.add(const Duration(seconds: 30))), isTrue);
    });

    test("represents secrets without expiry deterministically", () {
      const state = SecretFieldRevealed(value: "secret");

      expect(state.remainingDurationAt(DateTime.utc(3000)), isNull);
      expect(state.isExpiredAt(DateTime.utc(3000)), isFalse);
      expect(state.neverExpires, isTrue);
    });
  });
}

String _label(SecretFieldState state) => switch (state) {
  SecretFieldIdle() => "idle",
  SecretFieldLoading() => "loading",
  SecretFieldRevealed() => "revealed",
  SecretFieldExpired() => "expired",
  SecretFieldError() => "error",
};
