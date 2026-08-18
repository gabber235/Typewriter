import "package:freezed_annotation/freezed_annotation.dart";

part "secret_field_state.freezed.dart";

@freezed
sealed class SecretFieldState with _$SecretFieldState {
  const factory SecretFieldState.idle() = SecretFieldIdle;

  const factory SecretFieldState.loading() = SecretFieldLoading;

  const factory SecretFieldState.revealed({
    required String value,
    DateTime? expiresAt,
  }) = SecretFieldRevealed;

  const factory SecretFieldState.expired({required String value}) =
      SecretFieldExpired;

  const factory SecretFieldState.error({required String message}) =
      SecretFieldError;
}

extension SecretFieldRevealedTiming on SecretFieldRevealed {
  Duration? remainingDurationAt(DateTime now) {
    final expiry = expiresAt;
    if (expiry == null) return null;

    final remaining = expiry.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool isExpiredAt(DateTime now) {
    if (expiresAt == null) return false;
    return remainingDurationAt(now) == Duration.zero;
  }

  bool get neverExpires => expiresAt == null;
}
