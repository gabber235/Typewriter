import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
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
