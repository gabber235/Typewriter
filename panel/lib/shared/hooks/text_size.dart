import "package:typewriter_panel/typewriter_panel.dart";

/// Measures [text] as one left to right line using [context]'s text scale and
/// default text style merged with [style].
///
/// The result is memoized by [text] and [style]. Rebuild the hook with a new
/// dependency when other inherited text metrics must invalidate the cached
/// measurement.
Size useTextSize(BuildContext context, String text, [TextStyle? style]) {
  return useMemoized(() {
    final defaultTextStyle = DefaultTextStyle.of(context).style;

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: defaultTextStyle.merge(style)),
      maxLines: 1,
      textScaler: MediaQuery.of(context).textScaler,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);

    return textPainter.size;
  }, [text, style]);
}
