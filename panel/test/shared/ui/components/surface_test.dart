import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("transparent sections derive contrast from their actual canvas", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: const Surface(
        color: Colors.white,
        child: Section(
          backgroundColor: Colors.transparent,
          child: Text("Transparent"),
        ),
      ),
    );
    final element = tester.element(find.text("Transparent"));
    expect(Surface.colorOf(element), Colors.white);
    expect(Surface.foregroundOf(element), Colors.white.on(element));
  });
  testWidgets(
    "translucent surfaces publish the painted color and inherit foregrounds",
    (tester) async {
      late SurfaceAppearance observed;
      const parent = Color(0xff102030);
      const foreground = Color(0xfff0e0d0);
      const overlay = Color(0x80773322);
      await tester.pumpTestApp(
        child: Surface(
          color: parent,
          foreground: foreground,
          secondaryForeground: Colors.orange,
          child: Surface(
            color: overlay,
            child: Builder(
              builder: (context) {
                observed = Surface.appearanceOf(context);
                return const Text("Tag");
              },
            ),
          ),
        ),
      );
      expect(observed.color, Color.alphaBlend(overlay, parent));
      expect(observed.foreground, foreground);
      expect(observed.secondaryForeground, Colors.orange);
      expect(
        DefaultTextStyle.of(tester.element(find.text("Tag"))).style.color,
        foreground,
      );
    },
  );

  testWidgets(
    "supplied foreground reaches theme text and icons while leaf overrides survive",
    (tester) async {
      late SurfaceAppearance observed;
      late ThemeData theme;
      const foreground = Colors.yellow;
      await tester.pumpTestApp(
        child: Surface(
          color: Colors.black,
          foreground: foreground,
          child: Builder(
            builder: (context) {
              observed = Surface.appearanceOf(context);
              theme = Theme.of(context);
              return Column(
                children: [
                  Text("Inherited", style: theme.textTheme.titleMedium),
                  const Icon(Icons.label),
                  const Text("Explicit", style: TextStyle(color: Colors.green)),
                  const Icon(Icons.book, color: Colors.red),
                ],
              );
            },
          ),
        ),
      );
      expect(
        tester.widget<Text>(find.text("Inherited")).style?.color,
        foreground,
      );
      expect(
        IconTheme.of(tester.element(find.byIcon(Icons.label))).color,
        foreground,
      );
      expect(
        tester.widget<Text>(find.text("Explicit")).style?.color,
        Colors.green,
      );
      expect(tester.widget<Icon>(find.byIcon(Icons.book)).color, Colors.red);
      expect(
        observed.secondaryForeground,
        Color.alphaBlend(foreground.withValues(alpha: 0.7), observed.color),
      );
      expect(theme.colorScheme.primary, isNot(foreground));
    },
  );

  testWidgets(
    "captured themes retain the source appearance across an overlay boundary",
    (tester) async {
      CapturedThemes? captured;
      late SurfaceAppearance source;
      late SurfaceAppearance destination;
      await tester.pumpTestApp(
        child: Surface(
          color: Colors.blue,
          foreground: Colors.yellow,
          child: Builder(
            builder: (context) {
              source = Surface.appearanceOf(context);
              captured = InheritedTheme.capture(from: context, to: null);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpTestApp(
        child: Surface(
          color: Colors.red,
          foreground: Colors.green,
          child: captured!.wrap(
            Builder(
              builder: (context) {
                destination = Surface.appearanceOf(context);
                return const Text("Captured");
              },
            ),
          ),
        ),
      );
      expect(destination, source);
      expect(
        DefaultTextStyle.of(tester.element(find.text("Captured"))).style.color,
        Colors.yellow,
      );
    },
  );

  testWidgets(
    "animation contrast follows the displayed fill including interrupted transitions",
    (tester) async {
      var fill = Colors.black;
      late StateSetter update;
      late SurfaceAppearance observed;
      late Brightness brightness;
      const parent = Color(0xff203040);
      await tester.pumpTestApp(
        child: Surface(
          color: parent,
          child: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              brightness = Theme.brightnessOf(context);
              return SurfaceContainer(
                duration: const Duration(milliseconds: 100),
                decoration: BoxDecoration(color: fill),
                foregroundFor: (context, displayed) => displayed.on(context),
                child: Builder(
                  builder: (context) {
                    observed = Surface.appearanceOf(context);
                    return const Row(
                      children: [Icon(Icons.label), Text("Tag")],
                    );
                  },
                ),
              );
            },
          ),
        ),
      );
      update(() => fill = Colors.white);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final painter = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(SurfaceContainer),
              matching: find.byType(Container),
            )
            .first,
      );
      final painted = (painter.decoration! as BoxDecoration).color!;
      expect(painted, isNot(Colors.black));
      expect(painted, isNot(Colors.white));
      expect(observed.color, Color.alphaBlend(painted, parent));
      expect(observed.foreground, observed.color.onBrightness(brightness));
      expect(
        IconTheme.of(tester.element(find.byIcon(Icons.label))).color,
        observed.foreground,
      );
      expect(
        DefaultTextStyle.of(tester.element(find.text("Tag"))).style.color,
        observed.foreground,
      );
      final halfway = observed.color;
      update(() => fill = Colors.red.withValues(alpha: 0.25));
      await tester.pump();
      expect(observed.color, halfway);
      await tester.pumpAndSettle();
      expect(observed.color, Color.alphaBlend(fill, parent));
      expect(observed.foreground, observed.color.onBrightness(brightness));
      expect(tester.takeException(), isNull);
    },
  );
}
