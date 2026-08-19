part of "secret_field.dart";

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
