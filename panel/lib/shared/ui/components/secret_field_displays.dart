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
  return Theme.of(context).textTheme.titleSmall!
      .copyWith(fontVariations: [.weight(700)], letterSpacing: 1);
}

/// A blurred placeholder of random letters, drawn once per mount. While a
/// secret is generated the same placeholder sits under a shimmer, the
/// skeleton loop; it says nothing, so it never changes on its own.
class _ConcealedDisplay extends HookWidget {
  const _ConcealedDisplay({
    required this.prefix,
    required this.hasPrefix,
    this.loading = false,
  });

  final String? prefix;
  final bool hasPrefix;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final concealed = useMemoized(() {
      final random = Random();
      return _generateRandomString(
        hasPrefix ? 6 + random.nextInt(7) : 20 + random.nextInt(51),
      );
    });

    Widget placeholder = ImageFiltered(
      imageFilter: ImageFilter.compose(
        inner: ImageFilter.dilate(radiusX: 2, radiusY: 2),
        outer: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      ),
      child: Text(
        concealed,
        maxLines: 1,
        style: _secretTextStyle(context).copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant
              .withValues(alpha: 0.6),
        ),
      ),
    );
    if (loading) {
      placeholder = Shimmer(child: ShimmerLoading(child: placeholder));
    }

    return Text.rich(
      TextSpan(
        children: [
          if (prefix != null)
            TextSpan(text: prefix, style: _secretTextStyle(context)),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            // The blurred text only hints at a value; assistive technology
            // must not read a concealed or expired secret aloud.
            child: ExcludeSemantics(child: placeholder),
          ),
        ],
      ),
    );
  }
}

/// The revealed secret. A short value types in letter by letter; a value
/// longer than 20 letters arrives whole and stays selectable.
class _RevealedDisplay extends StatelessWidget {
  const _RevealedDisplay({required this.prefix, required this.value});

  final String? prefix;
  final String value;

  @override
  Widget build(BuildContext context) {
    final style = _secretTextStyle(context);
    if (value.length > 20) {
      return SelectableText(
        prefix != null ? "$prefix$value" : value,
        style: style,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (prefix != null) Text(prefix!, style: style),
        Flexible(child: MotionLabel(value, typesIn: true, style: style)),
      ],
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
            // The blurred text only hints at a value; assistive technology
            // must not read a concealed or expired secret aloud.
            child: ExcludeSemantics(
              child: ImageFiltered(
                imageFilter: ImageFilter.compose(
                  inner: ImageFilter.dilate(radiusX: 2, radiusY: 2),
                  outer: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                ),
                child: Text(
                  value,
                  style: _secretTextStyle(context).copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
