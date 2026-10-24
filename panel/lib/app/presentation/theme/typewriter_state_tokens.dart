import "package:typewriter_panel/typewriter_panel.dart";

/// Opacity and focus tokens used to resolve interactive widget states.
///
/// Disabled states return no overlay from [layer], allowing the component's
/// disabled colors to remain authoritative. Other states are resolved in
/// priority order, from pressed through dragged, focused, and hovered.
@immutable
class TypewriterStateTokens extends ThemeExtension<TypewriterStateTokens> {
  const TypewriterStateTokens({
    required this.focusRing,
    this.hoverOpacity = 0.08,
    this.focusOpacity = 0.12,
    this.pressedOpacity = 0.12,
    this.draggedOpacity = 0.16,
    this.disabledForegroundOpacity = 0.38,
    this.disabledContainerOpacity = 0.12,
  });

  final double hoverOpacity;
  final double focusOpacity;
  final double pressedOpacity;
  final double draggedOpacity;
  final double disabledForegroundOpacity;
  final double disabledContainerOpacity;
  final Color focusRing;

  /// Resolves the interaction layer for a set of [WidgetState] values.
  ///
  /// Returns `null` when no overlay should be painted, including disabled
  /// controls. When several states are present, the strongest interaction
  /// state wins according to the order documented on [TypewriterStateTokens].
  Color? layer(Color foreground, Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) return null;
    if (states.contains(WidgetState.pressed)) {
      return foreground.withValues(alpha: pressedOpacity);
    }
    if (states.contains(WidgetState.dragged)) {
      return foreground.withValues(alpha: draggedOpacity);
    }
    if (states.contains(WidgetState.focused)) {
      return focusRing.withValues(alpha: focusOpacity);
    }
    if (states.contains(WidgetState.hovered)) {
      return foreground.withValues(alpha: hoverOpacity);
    }
    return null;
  }

  /// Creates a Material state property backed by [layer].
  WidgetStateProperty<Color?> overlay(Color foreground) =>
      WidgetStateProperty.resolveWith((states) => layer(foreground, states));

  @override
  TypewriterStateTokens copyWith({
    double? hoverOpacity,
    double? focusOpacity,
    double? pressedOpacity,
    double? draggedOpacity,
    double? disabledForegroundOpacity,
    double? disabledContainerOpacity,
    Color? focusRing,
  }) => TypewriterStateTokens(
    hoverOpacity: hoverOpacity ?? this.hoverOpacity,
    focusOpacity: focusOpacity ?? this.focusOpacity,
    pressedOpacity: pressedOpacity ?? this.pressedOpacity,
    draggedOpacity: draggedOpacity ?? this.draggedOpacity,
    disabledForegroundOpacity:
        disabledForegroundOpacity ?? this.disabledForegroundOpacity,
    disabledContainerOpacity:
        disabledContainerOpacity ?? this.disabledContainerOpacity,
    focusRing: focusRing ?? this.focusRing,
  );

  @override
  TypewriterStateTokens lerp(covariant TypewriterStateTokens? other, double t) {
    if (other == null) return this;
    double l(double a, double b) => a + (b - a) * t;
    return TypewriterStateTokens(
      hoverOpacity: l(hoverOpacity, other.hoverOpacity),
      focusOpacity: l(focusOpacity, other.focusOpacity),
      pressedOpacity: l(pressedOpacity, other.pressedOpacity),
      draggedOpacity: l(draggedOpacity, other.draggedOpacity),
      disabledForegroundOpacity: l(
        disabledForegroundOpacity,
        other.disabledForegroundOpacity,
      ),
      disabledContainerOpacity: l(
        disabledContainerOpacity,
        other.disabledContainerOpacity,
      ),
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
    );
  }
}
