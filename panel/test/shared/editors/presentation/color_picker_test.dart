import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  const area = "Saturation and brightness";

  const initial = Color(0x807C4DFF);

  testWidgets("an opaque picker opens without opacity and closes with Escape", (
    tester,
  ) async {
    final (panel, _) = await tester.showColorField(
      initial,
      includeAlpha: false,
    );

    await panel.tapOn(find.tooltip("Open color picker"));
    expect(panel.shows(area), isTrue);
    expect(panel.shows("Opacity"), isFalse);

    await panel.press(LogicalKeyboardKey.escape);
    expect(panel.shows(area), isFalse);
  });

  testWidgets("a picker with alpha offers opacity", (tester) async {
    final (panel, _) = await tester.showColorField(initial, includeAlpha: true);

    await panel.tapOn(find.tooltip("Open color picker"));

    expect(panel.shows("Opacity"), isTrue);
  });

  testWidgets("opaque editing warns without mutating on mount", (tester) async {
    var changes = 0;
    final panel = await tester.showComponent(
      ColorPickerField(
        color: const Color(0x807C4DFF),
        includeAlpha: false,
        onChanged: (_) => changes++,
      ),
    );

    expect(changes, 0);
    await panel.tapOn(find.tooltip("Open color picker"));
    expect(find.textContaining("set alpha to FF"), findsOneWidget);
    expect(changes, 0);
  });

  testWidgets("invalid text remains visible without changing the binding", (
    tester,
  ) async {
    final (panel, color) = await tester.showColorField(
      initial,
      includeAlpha: true,
    );

    await panel.field("").type("123");

    expect(find.textContaining("six RGB or eight ARGB"), findsOneWidget);
    expect(panel.field("").value, "123");
    expect(color(), initial);
  });

  testWidgets("primary shortcuts switch field formats", (tester) async {
    final (panel, _) = await tester.showColorField(initial, includeAlpha: true);
    await panel.tapOn(find.tooltip("Open color picker"));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await panel.settle();

    for (final channel in ["R", "G", "B", "A%"]) {
      expect(find.text(channel), findsOneWidget, reason: channel);
    }
  });

  testWidgets("closed field exposes normal mode color shortcuts", (
    tester,
  ) async {
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == "Clipboard.setData") {
          clipboardText =
              (call.arguments as Map<Object?, Object?>)["text"] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final (panel, _) = await tester.showColorField(initial, includeAlpha: true);

    await panel.press(LogicalKeyboardKey.tab);
    await panel.pressPrimary(LogicalKeyboardKey.keyC);
    expect(clipboardText, "#807C4DFF");

    await panel.press(LogicalKeyboardKey.keyF);
    expect(find.tooltip("Remove from favorites"), findsOneWidget);

    await panel.press(LogicalKeyboardKey.keyP);
    expect(panel.shows(area), isTrue);
  });

  testWidgets("HSV surface keeps the top right hue fully bright", (
    tester,
  ) async {
    // The test's own capture point around the surface it paints.
    const boundaryKey = ValueKey("color_area_boundary");
    await tester.showComponent(
      RepaintBoundary(
        key: boundaryKey,
        child: SizedBox(
          width: 200,
          height: 100,
          child: ColorArea(
            color: HSVColor.fromAHSV(1, 0, 0.5, 0.5),
            onChanged: (_) {},
          ),
        ),
      ),
    );

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(boundaryKey),
    );
    final pixel = await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData();
      final value = bytes!.getUint32((image.width + 198) * 4);
      image.dispose();
      return value;
    });

    expect(pixel! >> 24 & 0xFF, greaterThan(245));
    expect(pixel >> 16 & 0xFF, lessThan(15));
    expect(pixel >> 8 & 0xFF, lessThan(15));
  });

  testWidgets("color area supports pointer and keyboard changes", (
    tester,
  ) async {
    var color = const HSVColor.fromAHSV(1, 180, 0.5, 0.5);
    final panel = await tester.showComponent(
      StatefulBuilder(
        builder: (context, setState) => SizedBox(
          width: 200,
          height: 100,
          child: ColorArea(
            color: color,
            onChanged: (next) => setState(() => color = next),
          ),
        ),
      ),
    );

    await tester.tapAt(
      tester.getBottomRight(panel.labeled(area)) - const Offset(1, 1),
    );
    await tester.pump();
    expect(color.saturation, closeTo(1, 0.01));
    expect(color.value, closeTo(0, 0.011));

    await tester.tap(panel.labeled(area));
    await panel.press(LogicalKeyboardKey.home);
    expect(color.saturation, 0);
    await panel.press(LogicalKeyboardKey.arrowRight);

    expect(color.saturation, closeTo(0.01, 0.001));
  });

  testWidgets("channel slider implements keyboard bounds", (tester) async {
    var value = 0.5;
    final panel = await tester.showComponent(
      StatefulBuilder(
        builder: (context, setState) => SizedBox(
          width: 200,
          child: ColorChannelSlider(
            label: "Hue",
            value: value,
            divisions: 100,
            gradient: const LinearGradient(colors: [Colors.red, Colors.blue]),
            onChanged: (next) => setState(() => value = next),
          ),
        ),
      ),
    );

    await tester.tap(panel.labeled("Hue"));
    await panel.press(LogicalKeyboardKey.end);
    expect(value, 1);
    await panel.press(LogicalKeyboardKey.pageDown);
    expect(value, closeTo(0.9, 0.001));
    await panel.press(LogicalKeyboardKey.home);
    expect(value, 0);
  });

  testWidgets("a read only field opens a picker that cannot change the color", (
    tester,
  ) async {
    final (panel, _) = await tester.showColorField(
      initial,
      includeAlpha: true,
      readOnly: true,
    );

    await panel.tapOn(find.tooltip("Open color picker"));

    expect(semanticsLabeled(area).single.isEnabled, isFalse);
  });

  testWidgets("a disabled field does not open its picker", (tester) async {
    final (panel, _) = await tester.showColorField(
      initial,
      includeAlpha: true,
      enabled: false,
    );

    // A disabled field takes no pointer input, so the click lands on the
    // field around the button.
    await tester.tapAt(
      tester.getCenter(find.tooltip("Open color picker"), warnIfMissed: false),
    );
    await panel.settle();

    expect(panel.shows(area), isFalse);
  });

  testWidgets("favorite grid supports keyboard reordering and removal", (
    tester,
  ) async {
    var colors = [0xFFFF0000, 0xFF00FF00, 0xFF0000FF];
    final panel = await tester.showComponent(
      StatefulBuilder(
        builder: (context, setState) => SizedBox(
          width: 200,
          child: ColorSwatchGrid(
            label: "Favorite colors",
            colors: colors,
            onSelected: (_) {},
            onRemoved: (value) => setState(() => colors.remove(value)),
            onReordered: (value) => setState(() => colors = value),
          ),
        ),
      ),
    );

    await tester.tap(panel.labeled("Color #FFFF0000"));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(colors, [0xFF00FF00, 0xFFFF0000, 0xFF0000FF]);

    await panel.press(LogicalKeyboardKey.delete);
    expect(colors, [0xFF00FF00, 0xFF0000FF]);
  });
}
