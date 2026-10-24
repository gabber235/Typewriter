import "package:typewriter_panel/typewriter_panel.dart";

/// Provides typed access to the Typewriter theme extensions installed by
/// `buildTheme`.
extension TypewriterThemeDataX on ThemeData {
  TypewriterColors get colors => extension<TypewriterColors>()!;
  TypewriterSpacing get spacing => extension<TypewriterSpacing>()!;
  TypewriterShapes get shapes => extension<TypewriterShapes>()!;
  TypewriterStateTokens get states => extension<TypewriterStateTokens>()!;
}

/// Provides the current theme and Typewriter design tokens to a widget.
///
/// These getters read the nearest [Theme] from the context. They therefore
/// must only be used while building below a Typewriter theme.
extension TypewriterThemeContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TypewriterColors get colors => theme.colors;
  TypewriterSpacing get spacing => theme.spacing;
  TypewriterShapes get shapes => theme.shapes;
  TypewriterStateTokens get stateTokens => theme.states;
}
