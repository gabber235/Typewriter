import "package:flutter/material.dart";
import "package:material_color_utilities/material_color_utilities.dart";

final safeColors = <Color>[
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

extension ColorExtension on Color {
  Color on(BuildContext context) {
    final brightness = Theme.brightnessOf(context);
    final schemeVariant = DynamicSchemeVariant.tonalSpot;
    final contrastLevel = 0.0;
    final scheme =
        _buildDynamicScheme(brightness, this, schemeVariant, contrastLevel);
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
