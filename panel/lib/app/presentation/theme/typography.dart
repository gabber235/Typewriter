import "package:flutter/material.dart";

TextStyle _style(String family, double size, double height, double weight) =>
    TextStyle(
      fontFamily: family,
      fontSize: size,
      height: height / size,
      fontVariations: [FontVariation("wght", weight)],
    );

TextTheme buildTypewriterTextTheme() => TextTheme(
  displayLarge: _style("JetBrainsMono", 40, 48, 700),
  displayMedium: _style("JetBrainsMono", 36, 44, 700),
  displaySmall: _style("JetBrainsMono", 32, 40, 700),
  headlineLarge: _style("JetBrainsMono", 28, 36, 700),
  headlineMedium: _style("JetBrainsMono", 26, 34, 700),
  headlineSmall: _style("JetBrainsMono", 22, 30, 650),
  titleLarge: _style("JetBrainsMono", 20, 28, 650),
  titleMedium: _style("JetBrainsMono", 16, 24, 650),
  titleSmall: _style("JetBrainsMono", 14, 20, 600),
  bodyLarge: _style("Lilex", 16, 24, 400),
  bodyMedium: _style("Lilex", 14, 20, 400),
  bodySmall: _style("Lilex", 12, 16, 400),
  labelLarge: _style("JetBrainsMono", 14, 20, 700),
  labelMedium: _style("JetBrainsMono", 13, 18, 700),
  labelSmall: _style("JetBrainsMono", 11, 16, 650),
);
