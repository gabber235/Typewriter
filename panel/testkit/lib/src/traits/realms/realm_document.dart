import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/core/world.dart";

/// The seeded Realm cannot read its saved document once the panel opened,
/// so authoring shows the content as unavailable with [failure].
Trait realmDocumentFails(Object failure) => _RealmDocumentFails(failure);

final class _RealmDocumentFails extends Trait {
  const _RealmDocumentFails(this.failure);

  final Object failure;

  @override
  Slot get slot => const Slot("realm document");

  @override
  String get description => "realmDocumentFails($failure)";

  @override
  void applyTo(WorldBuilder world) =>
      world.onStart((started) => started.requireRealm.fail(failure));
}
