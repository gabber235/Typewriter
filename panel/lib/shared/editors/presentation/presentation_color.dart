import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "presentation_color.freezed.dart";

/// An immutable observation of the color inputs supplied by the current owner.
///
/// Render objects may retain this observation for paint. Color expressions still
/// evaluate against the requested subject scope, with a fresh budget per color.
@freezed
abstract class PresentationColorEnvironment
    with _$PresentationColorEnvironment {
  const factory PresentationColorEnvironment({
    required ThemeData theme,
    required SurfaceAppearance appearance,
    required PresentationInteraction interaction,
  }) = _PresentationColorEnvironment;

  const PresentationColorEnvironment._();

  static PresentationColorEnvironment of(
    BuildContext context, {
    SurfaceAppearance? appearance,
  }) => PresentationColorEnvironment(
    theme: Theme.of(context),
    appearance: appearance ?? Surface.appearanceOf(context),
    interaction: PresentationInteractionScope.of(context),
  );

  /// Resolves typed color policy without changing any interaction state.
  /// Throws [PresentationColorFailure] for invalid or unavailable input.
  Color resolve(
    skir.PresentationColor color,
    PortablePresentationScope scope,
  ) => _PresentationColorResolver(this, scope).resolve(color);
}

final class PresentationColorFailure implements Exception {
  const PresentationColorFailure(this.message);
  final String message;
}

final class _PresentationColorResolver {
  _PresentationColorResolver(this.environment, this.scope)
    : remaining = scope.budget.maxSteps;

  final PresentationColorEnvironment environment;
  final PortablePresentationScope scope;
  SurfaceAppearance get appearance => environment.appearance;
  PresentationInteraction get interaction => environment.interaction;
  int remaining;

  void _visit(int depth) {
    if (--remaining < 0 || depth > 64) {
      throw const PresentationColorFailure(
        "Presentation color exceeds the evaluation budget",
      );
    }
  }

  bool _active(skir.PresentationInteractionState state) => switch (state.kind) {
    skir.PresentationInteractionState_kind.hoveredConst => interaction.hovered,
    skir.PresentationInteractionState_kind.selectedConst =>
      interaction.selected,
    skir.PresentationInteractionState_kind.focusedConst => interaction.focused,
    skir.PresentationInteractionState_kind.pressedConst => interaction.pressed,
    skir.PresentationInteractionState_kind.disabledConst =>
      interaction.disabled || !scope.enabled,
    _ => throw const PresentationColorFailure(
      "Presentation interaction state is unavailable",
    ),
  };

  Color resolve(skir.PresentationColor color, [int depth = 0]) {
    _visit(depth);
    Color next(skir.PresentationColor source) => resolve(source, depth + 1);
    switch (color) {
      case skir.PresentationColor_valueWrapper(:final value):
        switch (scope.evaluate(value)) {
          case PortableExpressionAvailable(value: final result)
              when result.authoredInteger != null:
            return Color(result.authoredInteger!.toUnsigned(32).toInt());
          case PortableExpressionFailed(:final message):
            throw PresentationColorFailure(message);
          case PortableExpressionUnavailable():
            throw const PresentationColorFailure(
              "Presentation color is unavailable",
            );
          default:
            throw const PresentationColorFailure(
              "Presentation color must evaluate to a color",
            );
        }
      case skir.PresentationColor_themeWrapper(:final value):
        final scheme = environment.theme.colorScheme;
        return switch (value.kind) {
          skir.PresentationThemeColor_kind.primaryConst => scheme.primary,
          skir.PresentationThemeColor_kind.onPrimaryConst => scheme.onPrimary,
          skir.PresentationThemeColor_kind.surfaceConst => scheme.surface,
          skir.PresentationThemeColor_kind.onSurfaceConst => scheme.onSurface,
          skir.PresentationThemeColor_kind.onSurfaceVariantConst =>
            scheme.onSurfaceVariant,
          skir.PresentationThemeColor_kind.focusOutlineConst =>
            environment.theme.brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          _ => throw const PresentationColorFailure(
            "Presentation theme color is unavailable",
          ),
        };
      case skir.PresentationColor_ambientWrapper(:final value):
        return switch (value.kind) {
          skir.PresentationAmbientColor_kind.backgroundConst =>
            appearance.color,
          skir.PresentationAmbientColor_kind.foregroundConst =>
            appearance.foreground,
          skir.PresentationAmbientColor_kind.secondaryForegroundConst =>
            appearance.secondaryForeground,
          _ => throw const PresentationColorFailure(
            "Presentation ambient color is unavailable",
          ),
        };
      case skir.PresentationColor_contrastWrapper(:final value):
        final background = Color.alphaBlend(
          next(value.source),
          appearance.color,
        );
        return switch (value.mode.kind) {
          skir.PresentationContrastMode_kind.tonalConst =>
            background.onBrightness(environment.theme.brightness),
          skir.PresentationContrastMode_kind.monochromeConst =>
            ThemeData.estimateBrightnessForColor(background) == Brightness.dark
                ? Colors.white
                : Colors.black,
          _ => throw const PresentationColorFailure(
            "Presentation contrast mode is unavailable",
          ),
        };
      case skir.PresentationColor_alphaWrapper(:final value):
        if (!value.alpha.isFinite || value.alpha < 0 || value.alpha > 1) {
          throw const PresentationColorFailure(
            "Presentation alpha must be between zero and one",
          );
        }
        final source = next(value.source);
        return source.withValues(alpha: source.a * value.alpha);
      case skir.PresentationColor_blendWrapper(:final value):
        return Color.alphaBlend(next(value.foreground), next(value.background));
      case skir.PresentationColor_statesWrapper(:final value):
        for (final rule in value.rules) {
          _visit(depth + 1);
          final required = rule.match.required_.toSet();
          final excluded = rule.match.excluded.toSet();
          if (required.intersection(excluded).isNotEmpty) {
            throw const PresentationColorFailure(
              "Presentation state match is contradictory",
            );
          }
          final requiredMatches = required.map(_active).toList();
          final excludedMatches = excluded.map(_active).toList();
          if (requiredMatches.every((active) => active) &&
              excludedMatches.every((active) => !active)) {
            return next(rule.color);
          }
        }
        return next(value.fallback);
      default:
        throw const PresentationColorFailure(
          "Presentation color variant is unavailable",
        );
    }
  }
}
