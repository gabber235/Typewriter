import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "presentation_motion.freezed.dart";

/// A service's motion read from the wire, or the message the presentation
/// diagnostic shows when it cannot be played.
@freezed
sealed class MotionReading<T> with _$MotionReading<T> {
  const factory MotionReading.read(T value) = MotionRead<T>;
  const factory MotionReading.failed(String message) = MotionReadFailed<T>;
}

/// A service's validated overrides, by the state whose change the move
/// belongs to.
@freezed
abstract class MoveOverrides with _$MoveOverrides {
  const factory MoveOverrides({
    MotionOverride? hovered,
    MotionOverride? focused,
    MotionOverride? pressed,
    MotionOverride? selected,
  }) = _MoveOverrides;

  const MoveOverrides._();

  /// The override for [move], or null so the move plays as tuned.
  MotionOverride? forMove(MotionToken<Landing> move) {
    if (move == MotionToken.press) return pressed;
    if (move == MotionToken.focusMove) return focused;
    if (move == MotionToken.ink) return selected;
    if (move == MotionToken.hoverIn || move == MotionToken.hoverOut) {
      return hovered;
    }
    return null;
  }
}

/// Reads one override.
extension PresentationTransitionReading on skir.PresentationTransition {
  MotionReading<MotionOverride> get reading {
    switch (this) {
      case skir.PresentationTransition_timedWrapper(:final value):
        return _timed(value);
      case skir.PresentationTransition_springWrapper(:final value):
        final valid =
            value.stiffness.isFinite &&
            value.stiffness > 0 &&
            value.damping.isFinite &&
            value.damping > 0;
        if (!valid) {
          return const MotionReading.failed(
            "Spring stiffness and damping must be finite and positive",
          );
        }
        return MotionReading.read(
          MotionOverride(
            curve: MotionShape.spring(
              stiffness: value.stiffness,
              damping: value.damping,
            ),
          ),
        );
      default:
        return const MotionReading.failed(
          "Presentation transition is unavailable",
        );
    }
  }
}

MotionReading<MotionOverride> _timed(skir.PresentationTimedTransition timed) {
  final milliseconds = timed.milliseconds;
  if (milliseconds != null && milliseconds < 0) {
    return const MotionReading.failed(
      "Presentation duration cannot be negative",
    );
  }
  final duration = milliseconds == null
      ? null
      : Duration(milliseconds: milliseconds);
  final curve = timed.curve;
  if (curve == null) {
    return MotionReading.read(MotionOverride(duration: duration));
  }
  return switch (_timedShape(curve)) {
    MotionRead(:final value) => MotionReading.read(
      MotionOverride(duration: duration, curve: value),
    ),
    MotionReadFailed(:final message) => MotionReading.failed(message),
  };
}

MotionReading<MotionShape> _timedShape(skir.PresentationTimedCurve curve) {
  switch (curve) {
    case skir.PresentationTimedCurve_strikeWrapper(:final value):
      return value.isFinite && value > 0 && value < 1
          ? MotionReading.read(MotionShape.timed(StrikeCurve(overshoot: value)))
          : const MotionReading.failed(
              "Strike overshoot must be between 0 and 1",
            );
    case skir.PresentationTimedCurve_carriageWrapper(:final value):
      // The hit point stays the engine's; only the recoil is sent.
      return value.isFinite && value >= 0 && value < 1
          ? MotionReading.read(MotionShape.timed(CarriageCurve(recoil: value)))
          : const MotionReading.failed(
              "Carriage recoil must be at least 0 and below 1",
            );
    default:
      return switch (curve.kind) {
        skir.PresentationTimedCurve_kind.exitConst => const MotionReading.read(
          MotionShape.exit,
        ),
        skir.PresentationTimedCurve_kind.easeOutConst =>
          const MotionReading.read(MotionShape.easeOut),
        skir.PresentationTimedCurve_kind.linearConst =>
          const MotionReading.read(MotionShape.linear),
        _ => const MotionReading.failed("Presentation curve is unavailable"),
      };
  }
}

MotionReading<MotionOverride?> _optional(
  skir.PresentationTransition? transition,
) {
  if (transition == null) return const MotionReading.read(null);
  return switch (transition.reading) {
    MotionRead(:final value) => MotionReading.read(value),
    MotionReadFailed(:final message) => MotionReading.failed(message),
  };
}

/// Reads a policy; no policy reads as no overrides.
extension PresentationTransitionPolicyReading
    on skir.PresentationTransitionPolicy? {
  MotionReading<MoveOverrides> get reading {
    final policy = this;
    if (policy == null) return const MotionReading.read(MoveOverrides());
    final read = <MotionOverride?>[];
    for (final transition in [
      policy.hovered,
      policy.focused,
      policy.pressed,
      policy.selected,
    ]) {
      switch (_optional(transition)) {
        case MotionRead(:final value):
          read.add(value);
        case MotionReadFailed(:final message):
          return MotionReading.failed(message);
      }
    }
    return MotionReading.read(
      MoveOverrides(
        hovered: read[0],
        focused: read[1],
        pressed: read[2],
        selected: read[3],
      ),
    );
  }
}

/// The overrides a collection sends for its items' arrival (rowIn) and
/// leave (listOut).
extension CollectionAppearanceMotion on skir.CollectionAppearance {
  /// Read null when the service sends none, so rowIn plays as tuned.
  MotionReading<MotionOverride?> get arrivalReading => _optional(itemArrival);

  /// Read null when the service sends none, so listOut plays as tuned.
  MotionReading<MotionOverride?> get leaveReading => _optional(itemLeave);
}

/// The motion a service paint value plays toward [target]: the move the
/// engine picks for the latest interaction change, with the service's
/// override for that same move. Reduced motion is applied by
/// resolveMotion, after the override.
ResolvedMotion<Landing> usePresentationMotion({
  required Object? target,
  required PresentationInteraction interaction,
  required MoveOverrides overrides,
}) {
  return useStateMotion(
    interaction.widgetStates,
    target: target,
    overrideFor: overrides.forMove,
  );
}
