import "package:flutter/material.dart";
import "package:typewriter_panel/app/presentation/theme/typewriter_colors.dart";

typedef _ColorFamily = ({
  Color color,
  Color onColor,
  Color container,
  Color onContainer,
});

const _brandColor = Color(0xFF009FFF);
const _accentColor = Colors.orange;
const _infoColor = Colors.blue;
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
  final blackContrast = _contrast(background, Colors.black);
  final whiteContrast = _contrast(background, Colors.white);
  return blackContrast >= whiteContrast ? Colors.black : Colors.white;
}

double _contrast(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

TypewriterColors buildTypewriterColors(Brightness brightness) {
  final neutral = _scheme(const Color(0xFF62646A), brightness);
  final brand = _family(_brandColor, brightness, neutral.surface);
  final accent = _family(_accentColor, brightness, neutral.surface);
  final info = _family(_infoColor, brightness, neutral.surface);
  final success = _family(_successColor, brightness, neutral.surface);
  final warning = _family(_warningColor, brightness, neutral.surface);
  final danger = _family(_dangerColor, brightness, neutral.surface);

  return TypewriterColors(
    brand: brand.color,
    onBrand: brand.onColor,
    brandContainer: brand.container,
    onBrandContainer: brand.onContainer,
    accent: accent.color,
    onAccent: accent.onColor,
    accentContainer: accent.container,
    onAccentContainer: accent.onContainer,
    canvas: neutral.surface,
    panel: brightness == Brightness.dark
        ? neutral.surface
        : neutral.surfaceContainerLow,
    surface: brightness == Brightness.dark
        ? neutral.surfaceContainerLow
        : neutral.surfaceContainerLowest,
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
    focusRing: neutral.outline,
    selection: brand.color,
    onSelection: brand.onColor,
    selectionContainer: brand.container,
    onSelectionContainer: brand.onContainer,
    shadow: neutral.shadow,
    scrim: neutral.scrim,
    info: info.color,
    onInfo: info.onColor,
    infoContainer: info.container,
    onInfoContainer: info.onContainer,
    success: success.color,
    onSuccess: success.onColor,
    successContainer: success.container,
    onSuccessContainer: success.onContainer,
    warning: warning.color,
    onWarning: warning.onColor,
    warningContainer: warning.container,
    onWarningContainer: warning.onContainer,
    danger: danger.color,
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
