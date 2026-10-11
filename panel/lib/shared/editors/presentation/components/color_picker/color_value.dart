import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Adapters between Flutter colors and Typewriter's unsigned ARGB values.
///
/// Typewriter stores colors as unsigned 32 bit integers in ARGB order. These
/// extensions centralize that representation so presentation controls do not
/// duplicate bit layout or formatting rules.
extension ColorArgbFormatting on Color {
  int get argbValue => toARGB32().toUnsigned(32);

  int get alphaByte => argbValue >> 24;

  int get redByte => argbValue >> 16 & 0xFF;

  int get greenByte => argbValue >> 8 & 0xFF;

  int get blueByte => argbValue & 0xFF;

  String formatHex({required bool includeAlpha}) {
    final value = includeAlpha ? argbValue : argbValue & 0xFFFFFF;
    final width = includeAlpha ? 8 : 6;
    return "#${value.toRadixString(16).padLeft(width, "0").toUpperCase()}";
  }

  skir.DataValue get asValue =>
      skir.DataValue.wrapInteger(argbValue.toString());
}

extension DataValueColor on skir.DataValue {
  Color? get asColorOrNull {
    final value = authoredInteger;
    if (value == null) return null;
    final maximum = BigInt.from(0xFFFFFFFF);
    if (value.isNegative || value > maximum) return null;
    return Color(value.toInt());
  }
}

/// Parses a six digit RGB or, when enabled, eight digit ARGB hexadecimal value.
///
/// A leading `#` or `0x` is accepted. Six digit input becomes opaque ARGB,
/// including when alpha capable input is enabled. Invalid syntax or length
/// throws [FormatException] for the validated field to display as an error.
Color parseColorHex(String source, {required bool includeAlpha}) {
  var value = source.trim();
  if (value.startsWith("#")) value = value.substring(1);
  if (value.startsWith("0x") || value.startsWith("0X")) {
    value = value.substring(2);
  }
  final validLength = value.length == 6 || includeAlpha && value.length == 8;
  if (!validLength || !RegExp(r"^[0-9A-Fa-f]+$").hasMatch(value)) {
    throw FormatException(
      includeAlpha
          ? "Enter six RGB or eight ARGB hexadecimal digits"
          : "Enter six RGB hexadecimal digits",
    );
  }

  final parsed = int.parse(value, radix: 16);
  return Color(value.length == 6 ? 0xFF000000 | parsed : parsed);
}

/// Builds a color from byte channels and an alpha percentage.
///
/// RGB values are clamped to 0 through 255. Alpha is clamped to 0 through
/// 100 percent and converted to the nearest representable byte.
Color colorFromChannels({
  required int red,
  required int green,
  required int blue,
  required int alphaPercent,
}) => Color.fromARGB(
  (alphaPercent.clamp(0, 100) * 255 / 100).round(),
  red.clamp(0, 255),
  green.clamp(0, 255),
  blue.clamp(0, 255),
);

/// Builds a color from HSL percentages and an alpha percentage.
///
/// Hue is clamped to 0 through 360 degrees. Saturation, lightness, and alpha
/// are clamped to their respective 0 through 100 percent ranges.
Color colorFromHsl({
  required double hue,
  required double saturationPercent,
  required double lightnessPercent,
  required int alphaPercent,
}) => HSLColor.fromAHSL(
  alphaPercent.clamp(0, 100) / 100,
  hue.clamp(0, 360),
  saturationPercent.clamp(0, 100) / 100,
  lightnessPercent.clamp(0, 100) / 100,
).toColor();

/// Converts [color] to HSV without losing hue when the color is grayscale.
///
/// HSV cannot recover a meaningful hue from zero saturation. The picker passes
/// its last saturated hue as [preservedHue] so changing value or saturation
/// after grayscale editing does not jump to an arbitrary hue.
HSVColor hsvWithPreservedHue(Color color, double preservedHue) {
  final hsv = HSVColor.fromColor(color);
  return hsv.saturation > 0.0001 ? hsv : hsv.withHue(preservedHue);
}
