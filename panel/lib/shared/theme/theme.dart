import "package:typewriter_panel/typewriter_panel.dart";

export "package:typewriter_panel/shared/theme/appearance.dart";
export "package:typewriter_panel/shared/theme/color_scheme.dart";
export "package:typewriter_panel/shared/theme/component_themes.dart";
export "package:typewriter_panel/shared/theme/motion.dart";
export "package:typewriter_panel/shared/theme/motion_table.dart";
export "package:typewriter_panel/shared/theme/motion_timeline.dart";
export "package:typewriter_panel/shared/theme/text_tone.dart";
export "package:typewriter_panel/shared/theme/typewriter_colors.dart";
export "package:typewriter_panel/shared/theme/typewriter_motion.dart";
export "package:typewriter_panel/shared/theme/typewriter_shapes.dart";
export "package:typewriter_panel/shared/theme/typewriter_spacing.dart";
export "package:typewriter_panel/shared/theme/typewriter_state_tokens.dart";
export "package:typewriter_panel/shared/theme/typewriter_text.dart";
export "package:typewriter_panel/shared/theme/typewriter_theme_access.dart";
export "package:typewriter_panel/shared/theme/typography.dart";

/// Builds the panel theme for [brightness].
///
/// The returned theme installs the Typewriter design tokens as theme
/// extensions, maps them into Material's [ColorScheme], and applies the
/// component defaults used across the panel. Keep light and dark behavior in
/// the token builders rather than overriding component colors at call sites.
///
/// [motion] is the token table, the standard one unless the panel's
/// `motionTableProvider` names another.
ThemeData buildTheme(Brightness brightness, {TypewriterMotion? motion}) {
  final colors = buildTypewriterColors(brightness);
  final spacing = TypewriterSpacing();
  final shapes = TypewriterShapes();
  final states = TypewriterStateTokens();
  final text = buildTypewriterText();
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
    extensions: [
      colors,
      spacing,
      shapes,
      states,
      text,
      motion ?? TypewriterMotion.standard(),
    ],
  );
  return applyComponentThemes(base, colors, spacing, shapes, states, text);
}
