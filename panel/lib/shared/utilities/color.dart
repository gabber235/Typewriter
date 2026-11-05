import "package:typewriter_panel/typewriter_panel.dart";

/// Accent palette for user selectable labels.
///
/// Choose a foreground with [ColorExtension.on] when using these as backgrounds.
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
