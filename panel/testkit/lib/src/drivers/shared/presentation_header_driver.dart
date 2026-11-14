import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/drivers/component_driver.dart";
import "package:typewriter_testkit/src/drivers/finders.dart";

/// The card of an authored presentation header the user reads as [title],
/// with what it says about the problems of the fields inside it.
final class PresentationHeaderDriver extends ComponentDriver {
  PresentationHeaderDriver(WidgetTester tester, this.title)
    : super(
        tester,
        find
            .ancestor(
              of: find.text(title),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );

  final String title;

  /// Whether the card carries the problem mark, whose tooltip counts the
  /// field diagnostics.
  bool get marked => find
      .descendant(
        of: scope!,
        matching: find.tooltip(RegExp(r"^\d+ field diagnostics?$")),
      )
      .evaluate()
      .isNotEmpty;

  /// Whether the card is tinted in a severity colour, judged by the colour
  /// it settles on.
  bool get tinted {
    final card = tester.widget<AnimatedContainer>(scope!);
    final color = (card.decoration as BoxDecoration?)?.color;
    return color != null && color.a > 0;
  }
}
