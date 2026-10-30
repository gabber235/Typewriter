import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _scope = "cloud.to.user.ada.organization.acme.members";
final _acme = acme.organizationId;

void main() {
  testWidgets("the member list applies added, updated and removed members", (
    tester,
  ) async {
    final ken = member("Ken");
    final grace = member("Grace");
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membershipBackend(members: [ken, grace]),
    ]);
    final members = panel.watch(organizationMembersProvider);
    await panel.eventually(() => expect(members.read().value, [ken, grace]));

    final linus = member("Linus");
    final renamed = member("Grace", email: "grace@typewriter.test");
    panel.world.nats.announceMembers(
      _acme,
      skir.OrganizationMembersChanged(
        sequence: 2,
        changes: [
          skir.OrganizationMembersChange.wrapAdd(linus),
          skir.OrganizationMembersChange.wrapUpdate(renamed),
          skir.OrganizationMembersChange.wrapRemove(ken.userId),
        ],
      ),
    );

    await panel.eventually(
      () => expect(members.read().value, [renamed, linus]),
    );
  });

  testWidgets("a missed member change reloads the member list", (tester) async {
    final grace = member("Grace");
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membershipBackend(members: [grace]),
    ]);
    final members = panel.watch(organizationMembersProvider);
    await panel.eventually(() => expect(members.read().value, [grace]));
    final linus = member("Linus");
    panel.world.nats.registerHandler(
      "$_scope.watch",
      (_) => skir.WatchOrganizationMembersResponse.serializer.toBytes(
        skir.WatchOrganizationMembersResponse.wrapSnapshot(
          skir.OrganizationMembersSnapshot(sequence: 4, values: [linus]),
        ),
      ),
    );

    panel.world.nats.announceMembers(
      _acme,
      skir.OrganizationMembersChanged(
        sequence: 4,
        changes: [skir.OrganizationMembersChange.wrapRemove(grace.userId)],
      ),
    );

    await panel.eventually(() => expect(members.read().value, [linus]));
  });

  testWidgets("join codes apply added and removed codes", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membershipBackend(joinCodes: [joinCode("first")]),
    ]);
    final codes = panel.watch(organizationJoinCodesProvider);
    await panel.eventually(
      () => expect(codes.read().value, [joinCode("first")]),
    );

    panel.world.nats.announceJoinCodes(
      _acme,
      skir.OrganizationJoinCodesChanged(
        sequence: 2,
        changes: [
          skir.OrganizationJoinCodesChange.wrapAdd(joinCode("second")),
          skir.OrganizationJoinCodesChange.wrapRemove(joinCode("first").code),
        ],
      ),
    );

    await panel.eventually(
      () => expect(codes.read().value, [joinCode("second")]),
    );
  });

  testWidgets("join requests apply added and removed requests", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membershipBackend(joinRequests: [joinRequest("first", name: "first")]),
    ]);
    final requests = panel.watch(organizationJoinRequestsProvider);
    await panel.eventually(
      () =>
          expect(requests.read().value, [joinRequest("first", name: "first")]),
    );

    panel.world.nats.announceJoinRequests(
      _acme,
      skir.OrganizationJoinRequestsChanged(
        sequence: 2,
        changes: [
          skir.OrganizationJoinRequestsChange.wrapAdd(
            joinRequest("second", name: "second"),
          ),
          skir.OrganizationJoinRequestsChange.wrapRemove(
            joinRequest("first", name: "first").requestId,
          ),
        ],
      ),
    );

    await panel.eventually(
      () => expect(requests.read().value, [
        joinRequest("second", name: "second"),
      ]),
    );
  });

  testWidgets("a join code change answered as the snapshot fails loading", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([signedIn(ada, organization: acme)]);
    panel.world.nats.registerHandler(
      "$_scope.join_codes.watch",
      (_) => skir.WatchOrganizationJoinCodesResponse.serializer.toBytes(
        skir.WatchOrganizationJoinCodesResponse.wrapChanged(
          skir.OrganizationJoinCodesChanged(sequence: 1, changes: const []),
        ),
      ),
    );

    final codes = panel.watch(organizationJoinCodesProvider);

    await panel.eventually(() => expect(codes.read().error, isStateError));
  });

  testWidgets("a join request change answered as the snapshot fails "
      "loading", (tester) async {
    // The sidebar watches join requests from the start, so the panel opens
    // on a healthy backend and asks again after the connection returns.
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membershipBackend(),
    ]);
    final requests = panel.watch(organizationJoinRequestsProvider);
    await panel.eventually(() => expect(requests.read().hasValue, isTrue));
    panel.world.nats.registerHandler(
      "$_scope.join_requests.watch",
      (_) => skir.WatchOrganizationJoinRequestsResponse.serializer.toBytes(
        skir.WatchOrganizationJoinRequestsResponse.wrapChanged(
          skir.OrganizationJoinRequestsChanged(sequence: 1, changes: const []),
        ),
      ),
    );

    panel.world.nats
      ..disconnect()
      ..reconnect();

    await panel.eventually(() => expect(requests.read().error, isStateError));
  });
}
