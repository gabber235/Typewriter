import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/core/world.dart";

/// The host of the seeded Realm stopped reporting, so the panel shows the
/// Realm offline while the backend itself stays reachable.
const Trait realmHostStopped = _RealmHostStopped();

final class _RealmHostStopped extends Trait {
  const _RealmHostStopped();

  @override
  Slot get slot => const Slot("realm host");

  @override
  String get description => "realmHostStopped";

  @override
  void applyTo(WorldBuilder world) => world.onStart(
    (world) => world.organizations.stopHost(world.requireRealm.scope.realmId),
  );
}
