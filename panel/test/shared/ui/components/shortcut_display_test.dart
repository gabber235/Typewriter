import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final backgrounds = <String, Color?>{
    "the theme's key color": null,
    "black": Colors.black,
    "white": Colors.white,
    "a saturated blue": const Color(0xFF1565C0),
    "a light yellow": const Color(0xFFFFF59D),
  };

  for (final theme in [null, dark]) {
    for (final MapEntry(key: name, value: background) in backgrounds.entries) {
      testWidgets("a solid key on $name stays readable"
          "${theme == null ? "" : " in the dark theme"}", (tester) async {
        await tester.pumpPanel(
          [?theme],
          at: PanelLocation.component(
            ShortcutDisplay(
              shortcut: const SingleActivator(LogicalKeyboardKey.keyA),
              style: KeyStyle.solid(backgroundColor: background),
            ),
          ),
        );

        final label = tester.renderObject<RenderParagraph>(find.text("A"));
        final key = paintedBackgroundBehind(label);

        expect(
          wcagContrast(label.text.style!.color!, key),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  }
}
