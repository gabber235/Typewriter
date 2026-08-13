import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

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

  IntegerValue get integerValue => IntegerValue(BigInt.from(argbValue));
}

extension IntegerValueColor on IntegerValue {
  Color? get colorOrNull {
    final maximum = BigInt.from(0xFFFFFFFF);
    if (value.isNegative || value > maximum) return null;
    return Color(value.toInt());
  }
}

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

HSVColor hsvWithPreservedHue(Color color, double preservedHue) {
  final hsv = HSVColor.fromColor(color);
  return hsv.saturation > 0.0001 ? hsv : hsv.withHue(preservedHue);
}
