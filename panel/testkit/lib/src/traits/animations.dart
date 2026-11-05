import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/core/world.dart";

/// Rive animations play through the real Rive runtime, for stories in a
/// browser; widget tests keep the empty boxes, since their runner has no
/// native Rive library.
const Trait liveAnimations = _LiveAnimations();

final class _LiveAnimations extends Trait {
  const _LiveAnimations();

  @override
  Slot get slot => const Slot("animations");

  @override
  String get description => "liveAnimations";

  @override
  void applyTo(WorldBuilder world) => world.liveAnimations = true;
}
