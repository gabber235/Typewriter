import "package:typewriter_panel/typewriter_panel.dart";

/// High contrast accent colors suitable for user selectable labels.
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

/// Color operations shared by theme and editor presentation code.
extension ColorsExtension on List<Color> {
  /// Blends colors by averaging HSV saturation, value, and alpha.
  ///
  /// Hue is averaged as a circular value, so red hues near zero do not blend
  /// through the unrelated colors between them. Throws for an empty list.
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
      final hueRadians = hsv.hue * pi / 180;
      hueX += cos(hueRadians) * hsv.saturation;
      hueY += sin(hueRadians) * hsv.saturation;

      saturation += hsv.saturation;

      value += hsv.value;
      alpha += hsv.alpha;
    }

    final hueVectorLength = sqrt(hueX * hueX + hueY * hueY);
    final hue = hueVectorLength < 1e-10
        ? 0.0
        : (atan2(hueY, hueX) * 180 / pi + 360) % 360;
    final count = length;

    return HSVColor.fromAHSV(
      alpha / count,
      hue,
      saturation / count,
      value / count,
    ).toColor();
  }
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance() + 0.05;
  final secondLuminance = second.computeLuminance() + 0.05;
  return firstLuminance >= secondLuminance
      ? firstLuminance / secondLuminance
      : secondLuminance / firstLuminance;
}

/// Chooses readable foreground colors for a color used as a background.
extension ColorExtension on Color {
  /// Returns a foreground color with sufficient contrast for the current theme.
  Color on(BuildContext context) => onBrightness(Theme.brightnessOf(context));

  /// Returns the dynamic theme foreground when it meets contrast requirements,
  /// otherwise chooses the higher contrast black or white fallback.
  Color onBrightness(Brightness brightness) {
    final schemeVariant = DynamicSchemeVariant.tonalSpot;
    final contrastLevel = 0.0;

    final scheme = _buildDynamicScheme(
      brightness,
      this,
      schemeVariant,
      contrastLevel,
    );

    final foreground = Color(MaterialDynamicColors.onPrimary.getArgb(scheme));
    if (_contrastRatio(this, foreground) >= 4.5) return foreground;
    final blackContrast = _contrastRatio(this, Colors.black);
    final whiteContrast = _contrastRatio(this, Colors.white);
    return blackContrast >= whiteContrast ? Colors.black : Colors.white;
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
