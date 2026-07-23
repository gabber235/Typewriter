import "package:flutter/material.dart";
import "package:typewriter_panel/app/presentation/theme/typewriter_colors.dart";
import "package:typewriter_panel/app/presentation/theme/typewriter_shapes.dart";
import "package:typewriter_panel/app/presentation/theme/typewriter_spacing.dart";
import "package:typewriter_panel/app/presentation/theme/typewriter_state_tokens.dart";

extension TypewriterThemeDataX on ThemeData {
  TypewriterColors get colors => extension<TypewriterColors>()!;
  TypewriterSpacing get spacing => extension<TypewriterSpacing>()!;
  TypewriterShapes get shapes => extension<TypewriterShapes>()!;
  TypewriterStateTokens get states => extension<TypewriterStateTokens>()!;
}

extension TypewriterThemeContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TypewriterColors get colors => theme.colors;
  TypewriterSpacing get spacing => theme.spacing;
  TypewriterShapes get shapes => theme.shapes;
  TypewriterStateTokens get stateTokens => theme.states;
}
