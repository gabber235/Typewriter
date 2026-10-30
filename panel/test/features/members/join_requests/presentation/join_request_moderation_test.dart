import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _scope = "cloud.to.user.ada.organization.acme.members";

final _request = skir.OrganizationJoinRequest(
  requestId: skir.recordId("request_to_join:grace"),
  userId: skir.recordId("user:grace"),
  userName: "Grace",
  userEmail: "grace@typewriter.test",
  userAvatarUrl: null,
  requestedAt: DateTime.utc(2026),
  expiresAt: DateTime.utc(2100),
);

final _editor = skir.OrganizationRole(
  roleId: skir.recordId("organization_role:editor"),
  name: "Editor",
  color: const Color(0xff2196f3).toSkirColor(),
  defaultRole: false,
  assignable: true,
  deletable: false,
);

void main() {
  testWidgets("a declined request is hidden while the decline sends, and "
      "a refusal brings back what the backend holds now", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membershipBackend(joinRequests: [_request]),
    ], at: membersPage(const JoinRequestsRoute()));
    final reply = Completer<Uint8List>();
    panel.world.nats.registerHandler(
      "$_scope.join_requests.decline",
      (_) => reply.future,
    );

    // The confirmation and the decline keep the panel busy until the reply
    // below, so these steps wait for what they need instead of settling.
    await tester.tap(find.text("Decline"));
    const question = "Decline Grace's request?";
    await panel.eventually(
      () => expect(panel.dialog.showing(question), isTrue),
    );
    final dialog = find.semantics
        .byPredicate((node) => node.spoken.contains(question))
        .evaluate()
        .last
        .route!;
    await tester.tapAt(dialog.button("Decline").screenRect.center);

    await panel.eventually(() => expect(find.text("Grace"), findsNothing));

    final linus = skir.OrganizationJoinRequest(
      requestId: skir.recordId("request_to_join:linus"),
      userId: skir.recordId("user:linus"),
      userName: "Linus",
      userEmail: "linus@typewriter.test",
      userAvatarUrl: null,
      requestedAt: DateTime.utc(2026),
      expiresAt: DateTime.utc(2100),
    );
    final member = skir.OrganizationMember(
      userId: skir.recordId("user:ken"),
      name: "Ken",
      email: null,
      avatarUrl: null,
      roles: const [],
      joinedAt: DateTime.utc(2026),
    );
    final members = panel.container.listen(
      organizationMembersProvider,
      (_, _) {},
    );
    addTearDown(members.close);
    await panel.eventually(() => expect(members.read().value, isEmpty));
    // Meanwhile the backend gained a request and a member.
    panel.world.nats
      ..registerHandler(
        "$_scope.join_requests.watch",
        (_) => skir.WatchOrganizationJoinRequestsResponse.serializer.toBytes(
          skir.WatchOrganizationJoinRequestsResponse.wrapSnapshot(
            skir.OrganizationJoinRequestsSnapshot(
              sequence: 5,
              values: [_request, linus],
            ),
          ),
        ),
      )
      ..registerHandler(
        "$_scope.watch",
        (_) => skir.WatchOrganizationMembersResponse.serializer.toBytes(
          skir.WatchOrganizationMembersResponse.wrapSnapshot(
            skir.OrganizationMembersSnapshot(sequence: 5, values: [member]),
          ),
        ),
      );

    reply.complete(
      skir.DeclineOrganizationJoinRequestResponse.serializer.toBytes(
        skir.DeclineOrganizationJoinRequestResponse.createRequestNotFoundError(
          requestId: _request.requestId,
        ),
      ),
    );
    await panel.eventually(() {
      expect(find.text("Grace"), findsOneWidget);
      expect(find.text("Linus"), findsOneWidget);
      expect(members.read().value, [member]);
    });
    await panel.settle();
  });

  testWidgets("a request cannot be approved until a role is chosen", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membership(roles: [_editor], joinRequests: [_request]),
    ], at: membersPage(const JoinRequestsRoute()));

    await panel.tapOn(find.text("Accept"));

    expect(semanticsLabeled("Confirm & Add Member").single.isEnabled, isFalse);

    await panel.tapOn(find.text("Editor"));

    expect(semanticsLabeled("Confirm & Add Member").single.isEnabled, isTrue);
  });
}
