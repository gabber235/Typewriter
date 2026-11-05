import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// The WCAG contrast ratio between two opaque colors, from 1 to 21.
double wcagContrast(Color a, Color b) {
  final lighter = a.computeLuminance();
  final darker = b.computeLuminance();
  final (high, low) = lighter > darker ? (lighter, darker) : (darker, lighter);
  return (high + 0.05) / (low + 0.05);
}

/// The color of the nearest painted box behind [label].
Color paintedBackgroundBehind(RenderObject label) {
  var node = label.parent;
  while (node != null) {
    if (node case RenderDecoratedBox(
      decoration: BoxDecoration(:final color?),
    )) {
      return color;
    }
    node = node.parent;
  }
  throw TestFailure("Nothing is painted behind the key label");
}

/// Reading how text was laid out.
extension ShownText on WidgetTester {
  /// The paragraph that lays out exactly [text].
  RenderParagraph paragraphOf(String text) => renderObject<RenderParagraph>(
    find.byWidgetPredicate(
      (widget) => widget is RichText && widget.text.toPlainText() == text,
    ),
  );
}

/// The size text is drawn at.
extension ScaledFontSize on RenderParagraph {
  /// The font size after the paragraph's text scaler applied.
  double get scaledFontSize => textScaler.scale(text.style!.fontSize!);
}

/// A text scaler that grows large text more than small text, the way
/// platform accessibility scaling can.
class NonlinearTextScaler extends TextScaler {
  const NonlinearTextScaler();

  @override
  double scale(double fontSize) => fontSize * (fontSize > 30 ? 1.8 : 1.4);

  @override
  double get textScaleFactor => 1.4;
}
