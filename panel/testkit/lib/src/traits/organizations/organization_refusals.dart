import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/core/world.dart";

/// The backend refuses some organization commands: an update to one of
/// [takenNames], which another organization uses, and every delete when
/// [deleteRefusal] is given. Everything else succeeds.
Trait organizationRefusals({
  Set<String> takenNames = const {},
  skir.OrganizationDeleteRefusal? deleteRefusal,
}) => _OrganizationRefusals(takenNames, deleteRefusal);

/// A delete refused because only the founder may delete the organization.
final founderRequired =
    skir.OrganizationDeleteRefusal.createFounderRequiredError();

final class _OrganizationRefusals extends Trait {
  const _OrganizationRefusals(this.takenNames, this.deleteRefusal);

  final Set<String> takenNames;
  final skir.OrganizationDeleteRefusal? deleteRefusal;

  @override
  Slot get slot => const Slot("organization refusals");

  @override
  String get description =>
      "organizationRefusals(taken: $takenNames, delete: $deleteRefusal)";

  @override
  void applyTo(WorldBuilder world) => world.onStart((started) {
    started.organizations
      ..takenNames.addAll(takenNames)
      ..deleteRefusal = deleteRefusal;
  });
}
