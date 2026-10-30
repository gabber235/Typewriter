import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/world.dart";
import "package:typewriter_testkit/src/doubles/nats.dart";

/// The membership commands of [organization] that [user], or nobody when
/// null, sends over [nats]; its session ends and it is disposed with the
/// test.
MembershipResourceRepository membershipCommands(
  FakeNatsClient nats, {
  required skir.RecordId organization,
  required String? user,
}) {
  final session = ResourceSession(
    SkirMutationClient(() => nats, () async => const NoopPanelTelemetry()),
    user,
  );
  final repository = MembershipResourceRepository(session, organization);
  addTearDown(repository.dispose);
  addTearDown(session.end);
  return repository;
}

/// Editing the roles of the open organization's members from a world.
extension MemberRoleEditing on World {
  /// Opens the role editor the way the members page does, watching the
  /// members and the roles until the test ends, and returns the members
  /// once they are listed.
  Future<OrganizationMembers> openRoleEditor() async {
    final members = container.listen(organizationMembersProvider, (_, _) {});
    final roles = container.listen(organizationRolesProvider, (_, _) {});
    addTearDown(members.close);
    addTearDown(roles.close);
    await container.read(organizationMembersProvider.future);
    return container.read(organizationMembersProvider.notifier);
  }
}
