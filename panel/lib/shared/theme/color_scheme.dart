import "package:typewriter_panel/typewriter_panel.dart";

typedef _ColorFamily = ({
  Color color,
  Color onColor,
  Color container,
  Color onContainer,
});

const _brandColor = Color(0xFF009FFF);
const _accentColor = Colors.orange;
// Violet, OKLCH about (0.58, 0.25, 288): brand stays the only blue.
const _infoColor = Color(0xFF7C4DFF);
const _successColor = Colors.green;
const _warningColor = Colors.orange;
const _dangerColor = Colors.redAccent;

ColorScheme _scheme(Color seed, Brightness brightness) =>
    ColorScheme.fromSeed(seedColor: seed, brightness: brightness);

_ColorFamily _family(Color color, Brightness brightness, Color surface) {
  final container = Color.alphaBlend(
    color.withValues(alpha: brightness == Brightness.dark ? 0.24 : 0.12),
    surface,
  );
  return (
    color: color,
    onColor: _contrastingForeground(color),
    container: container,
    onContainer: _contrastingForeground(container),
  );
}

Color _contrastingForeground(Color background) {
  final blackContrast = background.contrastWith(Colors.black);
  final whiteContrast = background.contrastWith(Colors.white);
  return blackContrast >= whiteContrast ? Colors.black : Colors.white;
}

/// Builds the semantic colors consumed by the panel design system.
///
/// Identity colors remain stable across brightnesses. Neutral surfaces and
/// their derived containers adapt to [brightness], and each semantic family
/// includes a contrasting foreground for use on its color and container.
/// Each status hue also gets a text twin that reads at 4.5:1 on every
/// surface and on its own container.
TypewriterColors buildTypewriterColors(Brightness brightness) {
  final neutral = _scheme(const Color(0xFF62646A), brightness);
  final dark = brightness == Brightness.dark;
  final canvas = neutral.surface;
  final panel = dark ? neutral.surface : neutral.surfaceContainerLow;
  final surface = dark
      ? neutral.surfaceContainerLow
      : neutral.surfaceContainerLowest;
  final textSurfaces = [
    canvas,
    panel,
    surface,
    neutral.surfaceContainer,
    neutral.surfaceContainerHigh,
    neutral.surfaceContainerHighest,
  ];
  final brand = _family(_brandColor, brightness, neutral.surface);
  final accent = _family(_accentColor, brightness, neutral.surface);
  final info = _family(_infoColor, brightness, neutral.surface);
  final success = _family(_successColor, brightness, neutral.surface);
  final warning = _family(_warningColor, brightness, neutral.surface);

  final danger = _family(_dangerColor, brightness, neutral.surface);
  Color text(_ColorFamily family) =>
      family.color.textTone(brightness, [...textSurfaces, family.container]);
  final brandText = text(brand);

  return TypewriterColors(
    brand: brand.color,
    brandText: brandText,
    onBrand: brand.onColor,
    brandContainer: brand.container,
    onBrandContainer: brand.onContainer,
    accent: accent.color,
    onAccent: accent.onColor,
    accentContainer: accent.container,
    onAccentContainer: accent.onContainer,
    canvas: canvas,
    panel: panel,
    surface: surface,
    surfaceContainer: neutral.surfaceContainer,
    surfaceRaised: neutral.surfaceContainerHigh,
    surfaceEmphasized: neutral.surfaceContainerHighest,
    contentPrimary: neutral.onSurface,
    contentSecondary: neutral.onSurfaceVariant,
    contentDisabled: neutral.onSurface.withValues(alpha: 0.38),
    contentInverse: neutral.onInverseSurface,
    border: neutral.outline,
    borderSubtle: neutral.outlineVariant,
    divider: neutral.outlineVariant,
    focusRing: dark ? _brandColor : brandText,
    selection: brand.color,
    onSelection: brand.onColor,
    selectionContainer: brand.container,
    onSelectionContainer: brand.onContainer,
    shadow: neutral.shadow,
    scrim: neutral.scrim,
    info: info.color,
    infoText: text(info),
    onInfo: info.onColor,
    infoContainer: info.container,
    onInfoContainer: info.onContainer,
    success: success.color,
    successText: text(success),
    onSuccess: success.onColor,
    successContainer: success.container,
    onSuccessContainer: success.onContainer,
    warning: warning.color,
    warningText: text(warning),
    onWarning: warning.onColor,
    warningContainer: warning.container,
    onWarningContainer: warning.onContainer,
    danger: danger.color,
    dangerText: text(danger),
    onDanger: danger.onColor,
    dangerContainer: danger.container,
    onDangerContainer: danger.onContainer,
    online: success.color,
    onOnline: success.onColor,
    onlineContainer: success.container,
    onOnlineContainer: success.onContainer,
    offline: neutral.secondary,
    onOffline: neutral.onSecondary,
    offlineContainer: neutral.secondaryContainer,
    onOfflineContainer: neutral.onSecondaryContainer,
  );
}

/// Maps Typewriter semantic tokens into Flutter's Material [ColorScheme].
///
/// [colors] is the source of truth for the panel's brand, surface, border, and
/// error roles. The remaining Material roles continue to come from the seeded
/// scheme so Material components have complete defaults.
ColorScheme buildColorScheme(Brightness brightness, TypewriterColors colors) {
  return ColorScheme.fromSeed(
    seedColor: colors.brand,
    brightness: brightness,
  ).copyWith(
    primary: colors.brand,
    onPrimary: colors.onBrand,
    primaryContainer: colors.brandContainer,
    onPrimaryContainer: colors.onBrandContainer,
    secondary: colors.accent,
    onSecondary: colors.onAccent,
    secondaryContainer: colors.accentContainer,
    onSecondaryContainer: colors.onAccentContainer,
    surface: colors.canvas,
    onSurface: colors.contentPrimary,
    onSurfaceVariant: colors.contentSecondary,
    surfaceContainerLowest: colors.surface,
    surfaceContainerLow: colors.panel,
    surfaceContainer: colors.surfaceContainer,
    surfaceContainerHigh: colors.surfaceRaised,
    surfaceContainerHighest: colors.surfaceEmphasized,
    outline: colors.border,
    outlineVariant: colors.borderSubtle,
    error: colors.danger,
    onError: colors.onDanger,
    errorContainer: colors.dangerContainer,
    onErrorContainer: colors.onDangerContainer,
    shadow: colors.shadow,
    scrim: colors.scrim,
  );
}
