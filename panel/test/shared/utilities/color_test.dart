import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/shared/utilities/color.dart";

void main() {
  group("ColorsExtension", () {
    group("mix", () {
      test("mixes hues across the color wheel seam", () {
        final colors = [
          HSVColor.fromAHSV(1, 350, 1, 1).toColor(),
          HSVColor.fromAHSV(1, 10, 1, 1).toColor(),
        ];

        final mixed = HSVColor.fromColor(colors.mix());

        expect(mixed.hue < 1 || mixed.hue > 359, isTrue);
      });

      test("mixes saturation and value arithmetically", () {
        final colors = [
          HSVColor.fromAHSV(1, 30, 0.5, 0.4).toColor(),
          HSVColor.fromAHSV(1, 30, 1, 0.8).toColor(),
        ];

        final mixed = HSVColor.fromColor(colors.mix());

        expect(mixed.hue, closeTo(30, 1));
        expect(mixed.saturation, closeTo(0.75, 0.01));
        expect(mixed.value, closeTo(0.6, 0.01));
      });

      test("ignores grayscale colors when mixing hue", () {
        final colors = [
          HSVColor.fromAHSV(1, 240, 1, 1).toColor(),
          HSVColor.fromAHSV(1, 0, 0, 1).toColor(),
        ];

        final mixed = HSVColor.fromColor(colors.mix());

        expect(mixed.hue, closeTo(240, 1));
        expect(mixed.saturation, closeTo(0.5, 0.01));
      });

      test("mixes alpha arithmetically", () {
        final colors = [
          HSVColor.fromAHSV(0.2, 120, 1, 1).toColor(),
          HSVColor.fromAHSV(0.8, 120, 1, 1).toColor(),
        ];

        final mixed = HSVColor.fromColor(colors.mix());

        expect(mixed.alpha, closeTo(0.5, 0.01));
      });

      test("throws for an empty list", () {
        expect(<Color>[].mix, throwsStateError);
      });
    });
  });
}
