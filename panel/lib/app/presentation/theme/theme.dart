import "package:flutter/material.dart";
import "package:typewriter_panel/app/presentation/theme/color_scheme.dart";
import "package:typewriter_panel/app/presentation/theme/component_themes.dart";
import "package:typewriter_panel/app/presentation/theme/typewriter_shapes.dart";
import "package:typewriter_panel/app/presentation/theme/typewriter_spacing.dart";
import "package:typewriter_panel/app/presentation/theme/typewriter_state_tokens.dart";
import "package:typewriter_panel/app/presentation/theme/typography.dart";

export "package:typewriter_panel/app/presentation/theme/color_scheme.dart";
export "package:typewriter_panel/app/presentation/theme/component_themes.dart";
export "package:typewriter_panel/app/presentation/theme/typewriter_colors.dart";
export "package:typewriter_panel/app/presentation/theme/typewriter_shapes.dart";
export "package:typewriter_panel/app/presentation/theme/typewriter_spacing.dart";
export "package:typewriter_panel/app/presentation/theme/typewriter_state_tokens.dart";
export "package:typewriter_panel/app/presentation/theme/typewriter_theme_access.dart";
export "package:typewriter_panel/app/presentation/theme/typography.dart";

/// Builds the panel theme for [brightness].
///
/// The returned theme installs the Typewriter design tokens as theme
/// extensions, maps them into Material's [ColorScheme], and applies the
/// component defaults used across the panel. Keep light and dark behavior in
/// the token builders rather than overriding component colors at call sites.
ThemeData buildTheme(Brightness brightness) {
  final colors = buildTypewriterColors(brightness);
  final spacing = TypewriterSpacing();
  final shapes = TypewriterShapes();
  final states = TypewriterStateTokens(focusRing: colors.focusRing);
  final colorScheme = buildColorScheme(brightness, colors);
  final textTheme = buildTypewriterTextTheme().apply(
    bodyColor: colorScheme.onSurface,
    displayColor: colorScheme.onSurface,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    textTheme: textTheme,
    extensions: [colors, spacing, shapes, states],
  );
  return applyComponentThemes(base, colors, spacing, shapes, states);
}
