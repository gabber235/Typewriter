import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("opens both picker variants and closes with escape", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: const _ColorFieldHarness(includeAlpha: false),
    );

    await tester.tap(find.byTooltip("Open color picker"));
    await tester.pumpAndSettle();
    expect(find.byType(ColorArea), findsOneWidget);
    expect(find.bySemanticsLabel("Opacity"), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(ColorArea), findsNothing);

    await tester.pumpTestApp(
      child: const _ColorFieldHarness(includeAlpha: true),
    );
    await tester.tap(find.byTooltip("Open color picker"));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel("Opacity"), findsOneWidget);
  });

  testWidgets("opaque editing warns without mutating on mount", (tester) async {
    var changes = 0;
    await tester.pumpTestApp(
      child: ColorPickerField(
        color: const Color(0x807C4DFF),
        includeAlpha: false,
        onChanged: (_) => changes++,
      ),
    );

    expect(changes, 0);
    await tester.tap(find.byTooltip("Open color picker"));
    await tester.pumpAndSettle();
    expect(find.textContaining("set alpha to FF"), findsOneWidget);
    expect(changes, 0);
  });

  testWidgets("invalid text remains visible without changing the binding", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: const _ColorFieldHarness(includeAlpha: true),
    );

    await tester.enterText(find.byType(TextFormField), "123");
    await tester.pump();
    expect(find.textContaining("six RGB or eight ARGB"), findsOneWidget);
    expect(
      tester.widget<_ColorFieldHarness>(find.byType(_ColorFieldHarness)),
      isNotNull,
    );
    expect(
      tester
          .widget<ValidatedTextField<Color>>(
            find.byType(ValidatedTextField<Color>),
          )
          .value,
      const Color(0x807C4DFF),
    );
  });

  testWidgets("primary shortcuts switch field formats", (tester) async {
    await tester.pumpTestApp(
      child: const _ColorFieldHarness(includeAlpha: true),
    );
    await tester.tap(find.byTooltip("Open color picker"));
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(find.text("R"), findsOneWidget);
    expect(find.text("G"), findsOneWidget);
    expect(find.text("B"), findsOneWidget);
    expect(find.text("A%"), findsOneWidget);
  });

  testWidgets("format selector uses the shared adaptive choice control", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: const _ColorFieldHarness(includeAlpha: true),
    );
    await tester.tap(find.byTooltip("Open color picker"));
    await tester.pumpAndSettle();

    expect(
      find.byType(AdaptiveChoiceControl<ColorFieldFormat>),
      findsOneWidget,
    );
  });

  testWidgets("channel labels render as colored field prefixes", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: const _ColorFieldHarness(includeAlpha: true),
    );
    await tester.tap(find.byTooltip("Open color picker"));
    await tester.pumpAndSettle();

    await tester.tap(find.text("RGB"));
    await tester.pumpAndSettle();

    final rgbLabels = <String, Color>{
      "R": tester.element(find.text("R")).colors.danger,
      "G": tester.element(find.text("G")).colors.success,
      "B": tester.element(find.text("B")).colors.info,
    };
    for (final entry in rgbLabels.entries) {
      final label = tester.widget<Text>(find.text(entry.key));
      expect(label.style?.color, entry.value);
      final decorator = tester.widget<InputDecorator>(
        find.ancestor(
          of: find.text(entry.key),
          matching: find.byType(InputDecorator),
        ),
      );
      expect(decorator.decoration.labelText, isNull);
    }

    await tester.tap(find.text("HSL"));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.text("H")).style?.color,
      tester.element(find.text("H")).colors.selection,
    );
    expect(
      tester.widget<Text>(find.text("S%")).style?.color,
      tester.element(find.text("S%")).colors.success,
    );
    expect(
      tester.widget<Text>(find.text("L%")).style?.color,
      tester.element(find.text("L%")).colors.warning,
    );
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

    await tester.pumpTestApp(
      child: const _ColorFieldHarness(includeAlpha: true),
      overrides: [
        colorLibraryStorageProvider.overrideWithValue(
          MemoryColorLibraryStorage(),
        ),
      ],
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    final modifier = isApple
        ? LogicalKeyboardKey.metaLeft
        : LogicalKeyboardKey.controlLeft;
    await tester.sendKeyDownEvent(modifier);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(modifier);
    await tester.pump();
    expect(clipboardText, "#807C4DFF");

    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.pumpAndSettle();
    expect(find.byTooltip("Remove from favorites"), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.pumpAndSettle();
    expect(find.byType(ColorArea), findsOneWidget);
  });

  testWidgets("HSV surface keeps the top right hue fully bright", (
    tester,
  ) async {
    const boundaryKey = ValueKey("color_area_boundary");
    await tester.pumpTestApp(
      child: RepaintBoundary(
        key: boundaryKey,
        child: SizedBox(
          width: 200,
          height: 100,
          child: ColorArea(
            color: HSVColor.fromAHSV(1, 0, 0.5, 0.5),
            onChanged: _ignoreHsv,
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
    await tester.pumpTestApp(
      child: StatefulBuilder(
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
      tester.getBottomRight(find.byType(ColorArea)) - const Offset(1, 1),
    );
    await tester.pump();
    expect(color.saturation, closeTo(1, 0.01));
    expect(color.value, closeTo(0, 0.011));

    await tester.tap(find.byType(ColorArea));
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(color.saturation, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(color.saturation, closeTo(0.01, 0.001));
  });

  testWidgets("channel slider implements keyboard bounds", (tester) async {
    var value = 0.5;
    await tester.pumpTestApp(
      child: StatefulBuilder(
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

    await tester.tap(find.byType(ColorChannelSlider));
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(value, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pump();
    expect(value, closeTo(0.9, 0.001));
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(value, 0);
  });

  testWidgets("read only allows inspection while disabled does not open", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: const _ColorFieldHarness(includeAlpha: true, readOnly: true),
    );
    await tester.tap(find.byTooltip("Open color picker"));
    await tester.pumpAndSettle();
    expect(find.byType(ColorArea), findsOneWidget);
    expect(tester.widget<ColorArea>(find.byType(ColorArea)).enabled, isFalse);

    await tester.pumpTestApp(
      child: const _ColorFieldHarness(includeAlpha: true, enabled: false),
    );
    expect(find.byTooltip("Open color picker"), findsNothing);
  });

  testWidgets("favorite grid supports keyboard reordering and removal", (
    tester,
  ) async {
    var colors = [0xFFFF0000, 0xFF00FF00, 0xFF0000FF];
    await tester.pumpTestApp(
      child: StatefulBuilder(
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

    await tester.tap(find.bySemanticsLabel("Color #FFFF0000"));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(colors, [0xFF00FF00, 0xFFFF0000, 0xFF0000FF]);

    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();
    expect(colors, [0xFF00FF00, 0xFF0000FF]);
  });
}

void _ignoreHsv(HSVColor value) {}

class _ColorFieldHarness extends StatefulWidget {
  const _ColorFieldHarness({
    required this.includeAlpha,
    this.enabled = true,
    this.readOnly = false,
  });

  final bool includeAlpha;
  final bool enabled;
  final bool readOnly;

  @override
  State<_ColorFieldHarness> createState() => _ColorFieldHarnessState();
}

class _ColorFieldHarnessState extends State<_ColorFieldHarness> {
  Color color = const Color(0x807C4DFF);

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 420,
    child: ColorPickerField(
      color: color,
      includeAlpha: widget.includeAlpha,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      onChanged: (next) => setState(() => color = next),
    ),
  );
}
