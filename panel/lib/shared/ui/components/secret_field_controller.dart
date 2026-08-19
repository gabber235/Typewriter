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

  useTimer(1.seconds, (_) {
    final currentState = state.value;
    if (currentState is! SecretFieldRevealed || currentState.neverExpires) {
      return;
    }

    if (currentState.remainingDurationAt(DateTime.now()) == Duration.zero) {
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
    await Clipboard.setData(ClipboardData(text: fullValue));
    field.onCopied?.call();
    if (context.mounted) {
      showSuccessSnackBar(context, field.copiedSnackbarText);
    }
  }

  Future<void> generate() async {
    state.value = const SecretFieldLoading();
    try {
      final result = await field.onGenerate();
      state.value = result.isExpiredAt(DateTime.now())
          ? SecretFieldExpired(value: result.value)
          : result;
      if (field.copyOnGenerate) {
        await copy();
      }
    } on Exception catch (error) {
      final message = error.toString();
      state.value = SecretFieldError(message: message);
      if (context.mounted) {
        showErrorSnackBar(context, "${field.errorSnackbarText}: $message");
      }
    }
  }

  return _SecretFieldController(
    state: state.value,
    generate: generate,
    copy: copy,
  );
}
