import "package:typewriter_panel/typewriter_panel.dart";

part "secret_field_state.freezed.dart";

/// The locally owned display and generation state of a [SecretField].
///
/// A revealed value may have an expiration. Once expired, the value remains
/// available to the display but is concealed and cannot be copied through the
/// field.
@freezed
sealed class SecretFieldState with _$SecretFieldState {
  /// No value has been generated, or the previous value is concealed.
  const factory SecretFieldState.idle() = SecretFieldIdle;

  /// [SecretField.onGenerate] is currently running.
  const factory SecretFieldState.loading() = SecretFieldLoading;

  /// A value is visible and may be copied until [expiresAt], if provided.
  const factory SecretFieldState.revealed({
    required String value,
    DateTime? expiresAt,
  }) = SecretFieldRevealed;

  /// An expired value is retained for concealed display and regeneration.
  const factory SecretFieldState.expired({required String value}) =
      SecretFieldExpired;

  /// Generation failed; [message] describes the caught exception.
  const factory SecretFieldState.error({required String message}) =
      SecretFieldError;
}

/// Provides expiry calculations without coupling state to the current clock.
extension SecretFieldRevealedTiming on SecretFieldRevealed {
  /// Returns the nonnegative time until expiry, or null when it never expires.
  Duration? remainingDurationAt(DateTime now) {
    final expiry = expiresAt;
    if (expiry == null) return null;

    final remaining = expiry.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Whether this value has expired at [now].
  bool isExpiredAt(DateTime now) {
    if (expiresAt == null) return false;
    return remainingDurationAt(now) == Duration.zero;
  }

  /// Whether this value remains copyable until manually replaced.
  bool get neverExpires => expiresAt == null;
}
