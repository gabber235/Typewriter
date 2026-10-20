import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "presentation_value_environment.freezed.dart";

/// An immutable observation of the theme, surface and interaction state the
/// current owner supplies to state driven paint values.
///
/// Colors, numbers and transitions all choose their value through the same
/// state match, so a rule such as "while selected" means the same thing for
/// every property. Render objects may retain this observation for paint.
/// Expressions still evaluate against the requested subject scope, with a
/// fresh budget per value.
@freezed
abstract class PresentationValueEnvironment
    with _$PresentationValueEnvironment {
  const factory PresentationValueEnvironment({
    required ThemeData theme,
    required SurfaceAppearance appearance,
    required PresentationInteraction interaction,
  }) = _PresentationValueEnvironment;

  const PresentationValueEnvironment._();

  static PresentationValueEnvironment of(
    BuildContext context, {
    SurfaceAppearance? appearance,
  }) => PresentationValueEnvironment(
    theme: Theme.of(context),
    appearance: appearance ?? Surface.appearanceOf(context),
    interaction: PresentationInteractionScope.of(context),
  );

  /// Whether [state] is active for [scope]. Disabled and read only also
  /// follow the scope, so an unavailable subtree matches without an owner.
  bool isActive(
    skir.PresentationInteractionState state,
    PortablePresentationScope scope,
  ) => switch (state.kind) {
    skir.PresentationInteractionState_kind.hoveredConst => interaction.hovered,
    skir.PresentationInteractionState_kind.selectedConst =>
      interaction.selected,
    skir.PresentationInteractionState_kind.focusedConst => interaction.focused,
    skir.PresentationInteractionState_kind.pressedConst => interaction.pressed,
    skir.PresentationInteractionState_kind.disabledConst =>
      interaction.disabled || !scope.enabled,
    skir.PresentationInteractionState_kind.readOnlyConst =>
      interaction.readOnly || scope.readOnly,
    skir.PresentationInteractionState_kind.invalidConst => interaction.invalid,
    skir.PresentationInteractionState_kind.routedConst => interaction.routed,
    _ => throw const PresentationColorFailure(
      "Presentation interaction state is unavailable",
    ),
  };

  /// Whether every required state is active and no excluded state is.
  /// Throws [PresentationColorFailure] for a contradictory match.
  bool matches(
    skir.PresentationStateMatch match,
    PortablePresentationScope scope,
  ) {
    final required = match.required_.toSet();
    final excluded = match.excluded.toSet();
    if (required.intersection(excluded).isNotEmpty) {
      throw const PresentationColorFailure(
        "Presentation state match is contradictory",
      );
    }
    return required.every((state) => isActive(state, scope)) &&
        excluded.every((state) => !isActive(state, scope));
  }

  /// The value of [value] in the current state: the first matching rule, or
  /// the fallback. Throws [PresentationColorFailure] when the chosen
  /// expression is unavailable or not a finite number.
  double number(
    skir.PresentationNumber value,
    PortablePresentationScope scope,
  ) {
    final expression = switch (value) {
      skir.PresentationNumber_valueWrapper(:final value) => value,
      skir.PresentationNumber_statesWrapper(:final value) =>
        value.rules
                .where((rule) => matches(rule.match, scope))
                .firstOrNull
                ?.value ??
            value.fallback,
      _ => throw const PresentationColorFailure(
        "Presentation number variant is unavailable",
      ),
    };
    final result = switch (scope.evaluate(expression)) {
      PortableExpressionAvailable(value: final result) =>
        switch (result.authoredPayload) {
          skir.DataValue_integerWrapper(:final value) => double.tryParse(value),
          skir.DataValue_floatWrapper(:final value) => value,
          skir.DataValue_decimalWrapper(:final value) => double.tryParse(value),
          _ => null,
        },
      PortableExpressionFailed(:final message) =>
        throw PresentationColorFailure(message),
      _ => null,
    };
    if (result == null || !result.isFinite) {
      throw const PresentationColorFailure(
        "Presentation number must be a finite number",
      );
    }
    return result;
  }

  /// How a change into the current state animates: the first rule matching
  /// it, or the fallback. Without a policy, changes apply at once.
  PresentationMotion motion(
    skir.PresentationTransitionPolicy? policy,
    PortablePresentationScope scope,
  ) {
    if (policy == null) return PresentationMotion.immediate;
    final transition =
        policy.rules
            .where((rule) => matches(rule.match, scope))
            .firstOrNull
            ?.transition ??
        policy.fallback;
    if (transition.milliseconds < 0) {
      throw const PresentationColorFailure(
        "Presentation duration cannot be negative",
      );
    }
    return PresentationMotion(
      duration: Duration(milliseconds: transition.milliseconds),
      curve: _curve(transition.curve),
    );
  }

  static Curve _curve(skir.PresentationCurve curve) => switch (curve) {
    skir.PresentationCurve_elasticOutWrapper(:final value) =>
      value.isFinite && value > 0
          ? ElasticOutCurve(value)
          : throw const PresentationColorFailure(
              "Elastic curve periods must be finite and positive",
            ),
    _ => switch (curve.kind) {
      skir.PresentationCurve_kind.linearConst => Curves.linear,
      skir.PresentationCurve_kind.easeInOutConst => Curves.easeInOut,
      skir.PresentationCurve_kind.easeOutConst => Curves.easeOut,
      skir.PresentationCurve_kind.emphasizedConst =>
        Curves.fastEaseInToSlowEaseOut,
      _ => throw const PresentationColorFailure(
        "Presentation curve is unavailable",
      ),
    },
  };
}

/// The duration and curve of one animated change.
@freezed
abstract class PresentationMotion with _$PresentationMotion {
  const factory PresentationMotion({
    required Duration duration,
    required Curve curve,
  }) = _PresentationMotion;

  /// Changes apply at once.
  static const immediate = PresentationMotion(
    duration: Duration.zero,
    curve: Curves.linear,
  );
}

/// A paint value, such as a color, number or alignment, that cannot be
/// resolved. Renderers show the message in place of the affected content.
final class PresentationColorFailure implements Exception {
  const PresentationColorFailure(this.message);
  final String message;
}
