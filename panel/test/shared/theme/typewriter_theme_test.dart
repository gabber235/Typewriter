import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  for (final brightness in Brightness.values) {
    group(brightness.name, () {
      late ThemeData theme;
      setUp(() => theme = buildTheme(brightness));

      test("semantic colors meet WCAG contrast", () {
        final c = theme.colors;
        final pairs = [
          (c.brand, c.onBrand),
          (c.brandContainer, c.onBrandContainer),
          (c.accent, c.onAccent),
          (c.info, c.onInfo),
          (c.success, c.onSuccess),
          (c.warning, c.onWarning),
          (c.danger, c.onDanger),
          (c.online, c.onOnline),
          (c.offline, c.onOffline),
        ];
        for (final (background, foreground) in pairs) {
          expect(
            wcagContrast(background, foreground),
            greaterThanOrEqualTo(4.5),
          );
        }
      });

      test("every text colour reads at 4.5:1 on every surface", () {
        final c = theme.colors;
        final text = {
          "contentPrimary": c.contentPrimary,
          "contentSecondary": c.contentSecondary,
          "brandText": c.brandText,
          "dangerText": c.dangerText,
          "successText": c.successText,
          "warningText": c.warningText,
          "infoText": c.infoText,
        };
        for (final MapEntry(key: name, value: color) in text.entries) {
          for (final surface in c.textSurfaces) {
            expect(
              wcagContrast(color, surface),
              greaterThanOrEqualTo(4.5),
              reason: "$name $color on $surface",
            );
          }
        }
      });

      test("text twins stay vivid: the most chroma their lightness allows", () {
        final c = theme.colors;
        for (final twin in [
          c.brandText,
          c.dangerText,
          c.successText,
          c.warningText,
          c.infoText,
        ]) {
          final tone = twin.oklch;
          expect(
            tone.chroma,
            greaterThan(tone.mostVivid.chroma - 0.01),
            reason: "$twin is duller than its gamut edge",
          );
        }
      });

      test(
        "dark twins keep their hue; light twins turn at most 10 degrees",
        () {
          final c = theme.colors;
          final pairs = [
            (c.brand, c.brandText),
            (c.danger, c.dangerText),
            (c.success, c.successText),
            (c.warning, c.warningText),
            (c.info, c.infoText),
          ];
          // Rounding to 8 bit sRGB moves the hue by up to 2 degrees.
          final limit = brightness == Brightness.dark ? 2.0 : 12.0;
          for (final (fill, text) in pairs) {
            expect(
              fill.oklch.hueDistanceDegrees(text.oklch),
              lessThanOrEqualTo(limit),
              reason: "$text as text of $fill",
            );
          }
        },
      );

      test("the focus ring reaches 3:1 on every surface", () {
        final c = theme.colors;
        for (final surface in c.textSurfaces) {
          expect(wcagContrast(c.focusRing, surface), greaterThanOrEqualTo(3));
        }
        expect(
          c.focusRing,
          brightness == Brightness.dark ? const Color(0xFF009FFF) : c.brandText,
        );
      });

      test("info is violet, so brand is the only blue", () {
        final hue = theme.colors.info.oklch.hue * 180 / pi % 360;
        expect(hue, inInclusiveRange(280, 300));
      });

      test("state precedence and disabled behavior are stable", () {
        final states = theme.states;
        final color = theme.colors.brand;
        expect(
          states.layer(color, {WidgetState.disabled, WidgetState.pressed}),
          isNull,
        );
        expect(
          states.layer(color, {WidgetState.pressed, WidgetState.focused}),
          color.withValues(alpha: states.pressedOpacity),
        );
        expect(
          states.layer(color, {WidgetState.dragged, WidgetState.focused}),
          color.withValues(alpha: states.draggedOpacity),
        );
        expect(
          states.layer(color, {WidgetState.focused}),
          isNull,
          reason: "focus is a ring, never a fill",
        );
        expect(
          states.layer(color, {WidgetState.focused, WidgetState.hovered}),
          color.withValues(alpha: states.hoverOpacity),
        );
      });
    });
  }
}
