import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";

/// Returns the size of the text with the given [style] in the given [context].
Size useTextSize(BuildContext context, String text, [TextStyle? style]) {
  return useMemoized(
    () {
      final defaultTextStyle = DefaultTextStyle.of(context).style;

      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: defaultTextStyle.merge(style),
        ),
        maxLines: 1,
        textScaler: MediaQuery.of(context).textScaler,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: double.infinity);

      return textPainter.size;
    },
    [text, style],
  );
}
