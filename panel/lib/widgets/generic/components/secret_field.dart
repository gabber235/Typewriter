import "dart:async";
import "dart:math";
import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/hooks/timer.dart";
import "package:typewriter_panel/utils/snackbar.dart";
import "package:typewriter_panel/widgets/generic/components/countdown_badge.dart";
import "package:typewriter_panel/widgets/generic/components/icones.dart";
import "package:typewriter_panel/widgets/generic/components/loading_button.dart";

sealed class SecretFieldState {
  const SecretFieldState();
}

class SecretFieldIdle extends SecretFieldState {
  const SecretFieldIdle();
}

class SecretFieldLoading extends SecretFieldState {
  const SecretFieldLoading();
}

class SecretFieldRevealed extends SecretFieldState {
  const SecretFieldRevealed({required this.value, this.expiresAt});

  final String value;
  final DateTime? expiresAt;

  Duration? get remainingDuration {
    if (expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return remainingDuration == Duration.zero;
  }

  bool get neverExpires => expiresAt == null;
}

class SecretFieldExpired extends SecretFieldState {
  const SecretFieldExpired({required this.value});

  final String value;
}

class SecretFieldError extends SecretFieldState {
  const SecretFieldError({required this.message});

  final String message;
}

class SecretField extends HookWidget {
  const SecretField({
    required this.title,
    required this.description,
    required this.onGenerate,
    this.prefix,
    this.generateButtonText = "Generate",
    this.regenerateButtonText = "Regenerate",
    this.copyButtonText = "Copy",
    this.expiredText = "Expired",
    this.copiedSnackbarText = "Copied to clipboard",
    this.errorSnackbarText = "Failed to generate",
    this.onCopied,
    this.onExpired,
    super.key,
  });

  final String title;
  final String description;
  final FutureOr<SecretFieldRevealed> Function() onGenerate;
  final String? prefix;
  final String generateButtonText;
  final String regenerateButtonText;
  final String copyButtonText;
  final String expiredText;
  final String copiedSnackbarText;
  final String errorSnackbarText;
  final VoidCallback? onCopied;
  final VoidCallback? onExpired;

  @override
  Widget build(BuildContext context) {
    final state = useState<SecretFieldState>(const SecretFieldIdle());

    useTimer(1.seconds, (timer) {
      final currentState = state.value;
      if (currentState is! SecretFieldRevealed) return;
      if (currentState.neverExpires) return;

      final remaining = currentState.remainingDuration;

      if (remaining == Duration.zero) {
        state.value = SecretFieldExpired(value: currentState.value);
        onExpired?.call();
      }
    });

    Future<void> handleGenerate() async {
      state.value = const SecretFieldLoading();
      try {
        final result = await onGenerate();
        state.value = result.isExpired
            ? SecretFieldExpired(value: result.value)
            : result;
      } on Exception catch (e) {
        final errorMessage = e.toString();
        state.value = SecretFieldError(message: errorMessage);
        if (context.mounted) {
          showErrorSnackBar(context, "$errorSnackbarText: $errorMessage");
        }
      }
    }

    Future<void> handleCopy() async {
      final currentState = state.value;
      final value = switch (currentState) {
        SecretFieldRevealed(:final value) => value,
        _ => null,
      };
      if (value == null) return;
      final fullValue = prefix != null ? "$prefix$value" : value;
      await Clipboard.setData(ClipboardData(text: fullValue));
      onCopied?.call();
      if (context.mounted) {
        showSuccessSnackBar(context, copiedSnackbarText);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        _SecretFieldContent(
          state: state.value,
          prefix: prefix,
          generateButtonText: generateButtonText,
          regenerateButtonText: regenerateButtonText,
          copyButtonText: copyButtonText,
          expiredText: expiredText,
          onGenerate: handleGenerate,
          onCopy: handleCopy,
        ),
      ],
    );
  }
}

class _SecretFieldContent extends StatelessWidget {
  const _SecretFieldContent({
    required this.state,
    required this.prefix,
    required this.generateButtonText,
    required this.regenerateButtonText,
    required this.copyButtonText,
    required this.expiredText,
    required this.onGenerate,
    required this.onCopy,
  });

  final SecretFieldState state;
  final String? prefix;
  final String generateButtonText;
  final String regenerateButtonText;
  final String copyButtonText;
  final String expiredText;
  final Future<void> Function() onGenerate;
  final Future<void> Function() onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.inputDecorationTheme.fillColor,
            borderRadius: .circular(12),
          ),
          padding: const .all(16),
          child: _buildSecretDisplay(context),
        ),
        const SizedBox(height: 12),
        _buildActions(context),
      ],
    );
  }

  Widget _buildSecretDisplay(BuildContext context) {
    final hasPrefix = prefix != null;

    return switch (state) {
      SecretFieldIdle() => _ConcealedDisplay(
        prefix: prefix,
        hasPrefix: hasPrefix,
      ),
      SecretFieldLoading() => _TypewriterLoadingDisplay(
        prefix: prefix,
        hasPrefix: hasPrefix,
      ),
      SecretFieldRevealed(:final value) => _RevealedDisplay(
        prefix: prefix,
        value: value,
      ),
      SecretFieldExpired(:final value) => _ExpiredDisplay(
        prefix: prefix,
        value: value,
      ),
      SecretFieldError() => _ConcealedDisplay(
        prefix: prefix,
        hasPrefix: hasPrefix,
      ),
    };
  }

  Widget _buildActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isIdle = state is SecretFieldIdle;
    final isError = state is SecretFieldError;
    final canCopy = state is SecretFieldRevealed;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runSpacing: 8,
      spacing: 8,
      children: [
        Wrap(
          runSpacing: 8,
          spacing: 8,
          children: [
            if (state is SecretFieldRevealed) ...[
              CountdownBadge(endDate: (state as SecretFieldRevealed).expiresAt),
              const SizedBox(width: 8),
            ],

            if (state is SecretFieldExpired) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icones(
                      MaterialSymbols.timer_off_rounded,
                      size: 14,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      expiredText,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            if (canCopy)
              LoadingButton.textIcon(
                onPressed: onCopy,
                icon: const Icones(
                  MaterialSymbols.content_copy_rounded,
                  size: 16,
                ),
                label: Text(copyButtonText),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            LoadingButton.filledIcon(
              onPressed: onGenerate,
              icon: const Icones(MaterialSymbols.autorenew_rounded, size: 16),
              label: Text(
                isIdle || isError ? generateButtonText : regenerateButtonText,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: isError ? colorScheme.error : null,
                foregroundColor: isError ? colorScheme.onError : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _generateRandomString(int length, {bool includeSpaces = false}) {
  const chars =
      "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  const charsWithSpaces = "$chars   ";
  final random = Random();
  final source = includeSpaces ? charsWithSpaces : chars;
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => source.codeUnitAt(random.nextInt(source.length)),
    ),
  );
}

TextStyle _secretTextStyle(BuildContext context) {
  return Theme.of(context).textTheme.titleSmall!.copyWith(
    fontFamily: "JetBrainsMono",
    fontVariations: [.weight(700)],
    letterSpacing: 1,
  );
}

class _ConcealedDisplay extends HookWidget {
  const _ConcealedDisplay({required this.prefix, required this.hasPrefix});

  final String? prefix;
  final bool hasPrefix;

  @override
  Widget build(BuildContext context) {
    final length = hasPrefix
        ? 6 + Random().nextInt(7)
        : 20 + Random().nextInt(51);
    final randomText = useState(_generateRandomString(length));

    useTimer(5.seconds, (_) {
      final newLength = hasPrefix
          ? 6 + Random().nextInt(7)
          : 20 + Random().nextInt(51);
      randomText.value = _generateRandomString(newLength);
    });

    return Text.rich(
      TextSpan(
        children: [
          if (prefix != null)
            TextSpan(text: prefix, style: _secretTextStyle(context)),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: ImageFiltered(
              imageFilter: ImageFilter.compose(
                inner: ImageFilter.dilate(radiusX: 2, radiusY: 2),
                outer: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              ),
              child: Text(
                randomText.value,
                style: _secretTextStyle(context).copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypewriterLoadingDisplay extends HookWidget {
  const _TypewriterLoadingDisplay({
    required this.prefix,
    required this.hasPrefix,
  });

  final String? prefix;
  final bool hasPrefix;

  @override
  Widget build(BuildContext context) {
    final random = useMemoized(Random.new);
    final minLength = hasPrefix ? 6 : 20;
    final maxExtra = hasPrefix ? 7 : 51;
    final targetText = useState(
      _generateRandomString(minLength + random.nextInt(maxExtra)),
    );
    final currentIndex = useState(1);
    final typingDelay = 50.ms;
    final waitTicks = (500 / typingDelay.inMilliseconds).floor();

    useTimer(typingDelay, (_) {
      if (currentIndex.value < targetText.value.length + waitTicks) {
        currentIndex.value++;
      } else {
        targetText.value = _generateRandomString(
          minLength + random.nextInt(maxExtra),
        );
        currentIndex.value = 1;
      }
    });

    final displayText = targetText.value.substring(
      0,
      min(currentIndex.value, targetText.value.length),
    );

    return Text.rich(
      TextSpan(
        children: [
          if (prefix != null)
            TextSpan(text: prefix, style: _secretTextStyle(context)),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: ImageFiltered(
              imageFilter: ImageFilter.compose(
                inner: ImageFilter.dilate(radiusX: 2, radiusY: 2),
                outer: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              ),
              child: Text(
                displayText,
                style: _secretTextStyle(context).copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevealedDisplay extends HookWidget {
  const _RevealedDisplay({required this.prefix, required this.value});

  final String? prefix;
  final String value;

  @override
  Widget build(BuildContext context) {
    final currentIndex = useState(1);
    final blurAmount = useState(4.0);
    final isAnimationComplete = useState(false);
    final animationDelay = 30.ms;

    useTimer(animationDelay, (_) {
      if (isAnimationComplete.value) return;

      var anyChange = false;

      if (currentIndex.value < value.length) {
        currentIndex.value++;
        anyChange = true;
      }

      if (blurAmount.value > 0) {
        blurAmount.value = (blurAmount.value - 0.6).clamp(0.0, 4.0);
        anyChange = true;
      }

      if (!anyChange) {
        isAnimationComplete.value = true;
      }
    });

    if (isAnimationComplete.value) {
      final fullText = prefix != null ? "$prefix$value" : value;
      return SelectableText(fullText, style: _secretTextStyle(context));
    }

    final displayText = value.substring(0, currentIndex.value);
    final currentBlur = blurAmount.value;

    return Text.rich(
      TextSpan(
        children: [
          if (prefix != null)
            TextSpan(text: prefix, style: _secretTextStyle(context)),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: ImageFiltered(
              imageFilter: currentBlur > 0.1
                  ? ImageFilter.blur(sigmaX: currentBlur, sigmaY: currentBlur)
                  : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: Text(displayText, style: _secretTextStyle(context)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpiredDisplay extends StatelessWidget {
  const _ExpiredDisplay({required this.prefix, required this.value});

  final String? prefix;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          if (prefix != null)
            TextSpan(text: prefix, style: _secretTextStyle(context)),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: ImageFiltered(
              imageFilter: ImageFilter.compose(
                inner: ImageFilter.dilate(radiusX: 2, radiusY: 2),
                outer: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              ),
              child: Text(
                value,
                style: _secretTextStyle(context).copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
