import "package:typewriter_panel/typewriter_panel.dart";

/// The family of every Material text role.
const textFamily = "Lilex";

/// The family of full sentences, used only by [TypewriterText].
const sentenceFamily = "IBMPlexSans";

TextStyle _style(String family, double size, double height, double weight) =>
    TextStyle(
      fontFamily: family,
      fontSize: size,
      height: height / size,
      fontVariations: [FontVariation("wght", weight)],
    );

/// Builds the Material text hierarchy used by the panel.
///
/// Every role is Lilex. Labels and buttons use weight 600, the smallest
/// label 500. Full sentences do not use these roles; they use
/// `context.text.sentence`. Line heights are explicit so dense editor
/// layouts remain stable.
TextTheme buildTypewriterTextTheme() => TextTheme(
  displayLarge: _style(textFamily, 40, 48, 700),
  displayMedium: _style(textFamily, 36, 44, 700),
  displaySmall: _style(textFamily, 32, 40, 700),
  headlineLarge: _style(textFamily, 28, 36, 700),
  headlineMedium: _style(textFamily, 26, 34, 700),
  headlineSmall: _style(textFamily, 22, 30, 650),
  titleLarge: _style(textFamily, 20, 28, 650),
  titleMedium: _style(textFamily, 16, 24, 650),
  titleSmall: _style(textFamily, 14, 20, 600),
  bodyLarge: _style(textFamily, 16, 24, 400),
  bodyMedium: _style(textFamily, 14, 20, 400),
  bodySmall: _style(textFamily, 12, 16, 400),
  labelLarge: _style(textFamily, 14, 20, 600),
  labelMedium: _style(textFamily, 13, 18, 600),
  labelSmall: _style(textFamily, 11, 16, 500),
);

/// A sentence style. Plex is bundled as static files, so weight selects a file.
TextStyle _sentence(double size, double height) => TextStyle(
  fontFamily: sentenceFamily,
  fontSize: size,
  height: height / size,
  fontWeight: FontWeight.w400,
);

/// Builds the sentence role installed as [TypewriterText].
TypewriterText buildTypewriterText() => TypewriterText(
  sentence: _sentence(14, 20),
  sentenceSmall: _sentence(12, 16),
);
