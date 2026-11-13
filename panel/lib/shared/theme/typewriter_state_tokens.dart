import "package:typewriter_panel/typewriter_panel.dart";

/// Opacity tokens used to resolve interactive widget states.
///
/// Disabled states return no overlay from [layer], allowing the component's
/// disabled colors to remain authoritative. Hover and press add no wash
/// either: a `Button` plays `hoverIn` and `press`, and reads [hoverOpacity]
/// and [pressedOpacity] only for its tint under reduced motion. Focus adds
/// no fill: the FocusRingLayer draws it as a ring. Only a drag washes.
@immutable
class TypewriterStateTokens extends ThemeExtension<TypewriterStateTokens> {
  const TypewriterStateTokens({
    this.hoverOpacity = 0.08,
    this.pressedOpacity = 0.12,
    this.draggedOpacity = 0.16,
    this.disabledForegroundOpacity = 0.38,
    this.disabledContainerOpacity = 0.12,
    this.splashOpacity = 0.26,
    this.splashOnFillOpacity = 0.45,
  });

  final double hoverOpacity;
  final double pressedOpacity;
  final double draggedOpacity;
  final double disabledForegroundOpacity;
  final double disabledContainerOpacity;

  /// The press splash on a soft or clear face, in the face's accent.
  final double splashOpacity;

  /// The press splash on a strong fill, in the fill's label colour.
  final double splashOnFillOpacity;

  /// Resolves the interaction layer for a set of [WidgetState] values.
  ///
  /// Returns `null` when no overlay should be painted, including disabled
  /// controls. When several states are present, the strongest interaction
  /// state wins according to the order documented on [TypewriterStateTokens].
  Color? layer(Color foreground, Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) return null;
    if (states.contains(WidgetState.dragged)) {
      return foreground.withValues(alpha: draggedOpacity);
    }
    return null;
  }

  /// Creates a Material state property backed by [layer].
  ///
  /// A control with no layer resolves to transparent rather than null, so
  /// Material's own hover, press and focus wash never fills it.
  WidgetStateProperty<Color?> overlay(Color foreground) =>
      WidgetStateProperty.resolveWith(
        (states) =>
            layer(foreground, states) ??
            (states.contains(WidgetState.disabled) ? null : Colors.transparent),
      );

  @override
  TypewriterStateTokens copyWith({
    double? hoverOpacity,
    double? pressedOpacity,
    double? draggedOpacity,
    double? disabledForegroundOpacity,
    double? disabledContainerOpacity,
    double? splashOpacity,
    double? splashOnFillOpacity,
  }) => TypewriterStateTokens(
    hoverOpacity: hoverOpacity ?? this.hoverOpacity,
    pressedOpacity: pressedOpacity ?? this.pressedOpacity,
    draggedOpacity: draggedOpacity ?? this.draggedOpacity,
    disabledForegroundOpacity:
        disabledForegroundOpacity ?? this.disabledForegroundOpacity,
    disabledContainerOpacity:
        disabledContainerOpacity ?? this.disabledContainerOpacity,
    splashOpacity: splashOpacity ?? this.splashOpacity,
    splashOnFillOpacity: splashOnFillOpacity ?? this.splashOnFillOpacity,
  );

  @override
  TypewriterStateTokens lerp(covariant TypewriterStateTokens? other, double t) {
    if (other == null) return this;
    double l(double a, double b) => a + (b - a) * t;
    return TypewriterStateTokens(
      hoverOpacity: l(hoverOpacity, other.hoverOpacity),
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
      splashOpacity: l(splashOpacity, other.splashOpacity),
      splashOnFillOpacity: l(splashOnFillOpacity, other.splashOnFillOpacity),
    );
  }
}
