import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("DataValue color adapters", () {
    test("converts a Flutter color to an unsigned integer value", () {
      expect(
        const Color(0x807C4DFF).asValue,
        IntegerValue(BigInt.from(0x807C4DFF)),
      );
    });

    test("converts valid integer values to Flutter colors", () {
      expect(
        IntegerValue(BigInt.from(0x807C4DFF)).asColorOrNull,
        const Color(0x807C4DFF),
      );
    });

    test("rejects non integer and out of range values", () {
      expect(const StringValue("#807C4DFF").asColorOrNull, isNull);
      expect(IntegerValue(BigInt.from(-1)).asColorOrNull, isNull);
      expect(IntegerValue(BigInt.from(0x100000000)).asColorOrNull, isNull);
    });
  });

  group("color hexadecimal parsing", () {
    test("accepts supported prefixes and formats Typewriter ARGB", () {
      expect(
        parseColorHex("#7C4DFF", includeAlpha: false).argbValue,
        0xFF7C4DFF,
      );
      expect(
        parseColorHex("0x807C4DFF", includeAlpha: true).argbValue,
        0x807C4DFF,
      );
      expect(
        const Color(0x807C4DFF).formatHex(includeAlpha: true),
        "#807C4DFF",
      );
    });

    test("normalizes six alpha capable digits to opaque", () {
      expect(parseColorHex("7c4dff", includeAlpha: true).argbValue, 0xFF7C4DFF);
    });

    test("rejects invalid lengths and characters", () {
      expect(
        () => parseColorHex("12345", includeAlpha: false),
        throwsFormatException,
      );
      expect(
        () => parseColorHex("GG7C4D", includeAlpha: false),
        throwsFormatException,
      );
      expect(
        () => parseColorHex("807C4DFF", includeAlpha: false),
        throwsFormatException,
      );
    });
  });

  test("channel conversion clamps and rounds alpha", () {
    final color = colorFromChannels(
      red: 300,
      green: -2,
      blue: 128,
      alphaPercent: 50,
    );
    expect(color.argbValue, 0x80FF0080);
  });

  test("HSL conversion produces stable channel values", () {
    final color = colorFromHsl(
      hue: 120,
      saturationPercent: 100,
      lightnessPercent: 50,
      alphaPercent: 25,
    );
    expect(color.argbValue, 0x4000FF00);
  });

  test("grayscale colors preserve the last meaningful hue", () {
    final gray = hsvWithPreservedHue(const Color(0xFF888888), 217);
    expect(gray.hue, 217);
    expect(gray.saturation, closeTo(0, 0.001));
  });
}
