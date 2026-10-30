import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/core/world.dart";

/// The Realm publication repository the panel really builds, talking to
/// [World.nats] instead of the publication double a seeded Realm serves.
///
/// Use it for tests of the publication wire protocol: the subjects requested,
/// the replies decoded, and what a lost or unknown reply does. It needs no
/// [realm] trait, so the test chooses the Realm id it asks for.
Trait realmPublicationOverNats() => const _RealmPublicationOverNats();

final class _RealmPublicationOverNats extends Trait {
  const _RealmPublicationOverNats();

  @override
  Slot get slot => const Slot("realm publication repository");

  @override
  String get description => "realmPublicationOverNats()";

  @override
  void applyTo(WorldBuilder world) => world.overrides.add(
    realmPublicationRepositoryProvider.overrideWith(
      (ref, ids) => NatsRealmPublicationRepository(
        ref: ref,
        organizationId: ids.$1,
        realmId: ids.$2,
      ),
    ),
  );
}
