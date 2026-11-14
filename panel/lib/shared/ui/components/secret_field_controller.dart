part of "secret_field.dart";

class _SecretFieldController {
  const _SecretFieldController({
    required this.state,
    required this.generate,
    required this.copy,
  });

  final SecretFieldState state;
  final Future<void> Function() generate;
  final Future<void> Function() copy;
}

_SecretFieldController _useSecretFieldController(
  BuildContext context,
  SecretField field,
) {
  final state = useState<SecretFieldState>(const SecretFieldIdle());

  useTimer(const Duration(seconds: 1), (_) {
    final currentState = state.value;
    if (currentState is! SecretFieldRevealed || currentState.neverExpires) {
      return;
    }

    if (currentState.remainingDurationAt(clock.now()) == Duration.zero) {
      state.value = SecretFieldExpired(value: currentState.value);
      field.onExpired?.call();
    }
  });

  Future<void> copy() async {
    final value = switch (state.value) {
      SecretFieldRevealed(:final value) => value,
      _ => null,
    };
    if (value == null) return;

    final fullValue = field.prefix != null ? "${field.prefix}$value" : value;
    try {
      await Clipboard.setData(ClipboardData(text: fullValue));
    } on PlatformException {
      // A browser can refuse the page the clipboard. The value stays on
      // screen and the pressed button jams with this message.
      throw _SecretFieldFailure(field.copyFailedText);
    }
    field.onCopied?.call();
  }

  Future<void> generate() async {
    state.value = const SecretFieldLoading();
    try {
      final result = await field.onGenerate();
      state.value = result.isExpiredAt(clock.now())
          ? SecretFieldExpired(value: result.value)
          : result;
    } on Exception catch (error) {
      final message = error.toString();
      state.value = SecretFieldError(message: message);
      // The generate button jams and shows this; it never says Copied.
      throw _SecretFieldFailure("${field.errorText}: $message");
    }
    // The generate button then says Copied, or jams when the browser refuses.
    if (field.copyOnGenerate) await copy();
  }

  return _SecretFieldController(
    state: state.value,
    generate: generate,
    copy: copy,
  );
}

/// A failed generate or copy; [message] is what the pressed button shows.
class _SecretFieldFailure implements Exception {
  const _SecretFieldFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
