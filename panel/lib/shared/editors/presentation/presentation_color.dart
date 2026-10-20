import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Resolves typed color policy against an environment's theme, surface and
/// interaction state without changing any of them.
extension PresentationColorResolution on PresentationValueEnvironment {
  /// Throws [PresentationColorFailure] for invalid or unavailable input.
  Color resolve(
    skir.PresentationColor color,
    PortablePresentationScope scope,
  ) => _PresentationColorResolver(this, scope).resolve(color);
}

final class _PresentationColorResolver {
  _PresentationColorResolver(this.environment, this.scope)
    : remaining = scope.budget.maxSteps;

  final PresentationValueEnvironment environment;
  final PortablePresentationScope scope;
  SurfaceAppearance get appearance => environment.appearance;
  int remaining;

  void _visit(int depth) {
    if (--remaining < 0 || depth > 64) {
      throw const PresentationColorFailure(
        "Presentation color exceeds the evaluation budget",
      );
    }
  }

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
          if (environment.matches(rule.match, scope)) return next(rule.color);
        }
        return next(value.fallback);
      case skir.PresentationColor_adjustedWrapper(:final value):
        return _adjusted(next(value.source), value.lightness, value.chroma);
      case skir.PresentationColor_brightnessWrapper(:final value):
        return next(
          environment.theme.brightness == Brightness.dark
              ? value.dark
              : value.light,
        );
      default:
        throw const PresentationColorFailure(
          "Presentation color variant is unavailable",
        );
    }
  }
}

/// Moves [source] in OkLch: negative [lightness] toward black and positive
/// toward white, negative [chroma] toward gray and positive toward full
/// saturation. Opacity is kept.
Color _adjusted(Color source, double lightness, double chroma) {
  if (!lightness.isFinite ||
      !chroma.isFinite ||
      lightness.abs() > 1 ||
      chroma.abs() > 1) {
    throw const PresentationColorFailure(
      "Presentation color adjustments must be between minus one and one",
    );
  }
  var color = source.toOkLch();
  color = lightness < 0 ? color.darker(-lightness) : color.lighter(lightness);
  color = chroma < 0 ? color.desaturate(-chroma) : color.saturate(chroma);
  return color.toColor().withValues(alpha: source.a);
}
