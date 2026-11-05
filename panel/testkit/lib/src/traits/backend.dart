import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/core/world.dart";

/// The backend answers only over NATS: the organization list, topology and
/// services run as the panel's real projections against [World.nats], where
/// the test registers replies and emits changes.
///
/// For tests of those projections themselves; every other test keeps the
/// organization doubles.
const Trait backendOverNats = _BackendOverNats();

final class _BackendOverNats extends Trait {
  const _BackendOverNats();

  @override
  Slot get slot => const Slot("backend");

  @override
  String get description => "backendOverNats";

  @override
  void applyTo(WorldBuilder world) => world.organizationDoubles = false;
}
