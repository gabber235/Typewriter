import "dart:math" as math;

import "package:flutter/material.dart";
import "package:material_color_utilities/material_color_utilities.dart";

const safeColors = <Color>[
  Colors.pinkAccent,
  Colors.redAccent,
  Colors.orange,
  Colors.amber,
  Color(0xFF5fc062),
  Color(0xFF02c486),
  Color(0xFF09b2fe),
  Colors.blueAccent,
  Color(0xFF967bfa),
  Colors.purpleAccent,
];

extension ColorsExtension on List<Color> {
  /// An HSV circular hue mixing algorithm that evenly distributes colors across the color wheel.
  Color mix() {
    if (isEmpty) {
      throw StateError("Cannot mix an empty color list.");
    }

    var hueX = 0.0;
    var hueY = 0.0;
    var saturation = 0.0;
    var value = 0.0;
    var alpha = 0.0;

    for (final color in this) {
      final hsv = HSVColor.fromColor(color);
      final hueRadians = hsv.hue * math.pi / 180;
      hueX += math.cos(hueRadians) * hsv.saturation;
      hueY += math.sin(hueRadians) * hsv.saturation;
      saturation += hsv.saturation;
      value += hsv.value;
      alpha += hsv.alpha;
    }

    final hueVectorLength = math.sqrt(hueX * hueX + hueY * hueY);
    final hue = hueVectorLength < 1e-10
        ? 0.0
        : (math.atan2(hueY, hueX) * 180 / math.pi + 360) % 360;
    final count = length;

    return HSVColor.fromAHSV(
      alpha / count,
      hue,
      saturation / count,
      value / count,
    ).toColor();
  }
}

extension ColorExtension on Color {
  Color on(BuildContext context) => onBrightness(Theme.brightnessOf(context));
  Color onBrightness(Brightness brightness) {
    final schemeVariant = DynamicSchemeVariant.tonalSpot;
    final contrastLevel = 0.0;
    final scheme = _buildDynamicScheme(
      brightness,
      this,
      schemeVariant,
      contrastLevel,
    );
    return Color(MaterialDynamicColors.onPrimary.getArgb(scheme));
  }
}

DynamicScheme _buildDynamicScheme(
  Brightness brightness,
  Color seedColor,
  DynamicSchemeVariant schemeVariant,
  double contrastLevel,
) {
  assert(
    contrastLevel >= -1.0 && contrastLevel <= 1.0,
    "contrastLevel must be between -1.0 and 1.0 inclusive.",
  );
  final isDark = brightness == Brightness.dark;
  final sourceColor = Hct.fromInt(seedColor.toARGB32());
  return switch (schemeVariant) {
    DynamicSchemeVariant.tonalSpot => SchemeTonalSpot(
      sourceColorHct: sourceColor,
      isDark: isDark,
      contrastLevel: contrastLevel,
    ),
    DynamicSchemeVariant.fidelity => SchemeFidelity(
      sourceColorHct: sourceColor,
      isDark: isDark,
      contrastLevel: contrastLevel,
    ),
    DynamicSchemeVariant.content => SchemeContent(
      sourceColorHct: sourceColor,
      isDark: isDark,
      contrastLevel: contrastLevel,
    ),
    DynamicSchemeVariant.monochrome => SchemeMonochrome(
      sourceColorHct: sourceColor,
      isDark: isDark,
      contrastLevel: contrastLevel,
    ),
    DynamicSchemeVariant.neutral => SchemeNeutral(
      sourceColorHct: sourceColor,
      isDark: isDark,
      contrastLevel: contrastLevel,
    ),
    DynamicSchemeVariant.vibrant => SchemeVibrant(
      sourceColorHct: sourceColor,
      isDark: isDark,
      contrastLevel: contrastLevel,
    ),
    DynamicSchemeVariant.expressive => SchemeExpressive(
      sourceColorHct: sourceColor,
      isDark: isDark,
      contrastLevel: contrastLevel,
    ),
    DynamicSchemeVariant.rainbow => SchemeRainbow(
      sourceColorHct: sourceColor,
      isDark: isDark,
      contrastLevel: contrastLevel,
    ),
    DynamicSchemeVariant.fruitSalad => SchemeFruitSalad(
      sourceColorHct: sourceColor,
      isDark: isDark,
      contrastLevel: contrastLevel,
    ),
  };
}
