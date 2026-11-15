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
  testWidgets("holding Decline keeps the request listed and struck through "
      "while the decline sends, and a refusal leaves it listed with the "
      "refusal under it", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membershipBackend(joinRequests: [_request]),
    ], at: membersPage(const JoinRequestsRoute()));
    final reply = Completer<Uint8List>();
    panel.world.nats.registerHandler(
      "$_scope.join_requests.decline",
      (_) => reply.future,
    );

    await panel.item("Grace").select();
    final gesture = await tester.startGesture(
      tester.getCenter(find.bySemanticsLabel(RegExp(r"^Decline Grace\?")).last),
    );
    await panel.holdFor(1);
    await gesture.up();
    await tester.pump();

    expect(panel.onPage("Grace"), findsOneWidget);
    expect(
      tester.textDecorationOf(panel.onPage("Grace")),
      TextDecoration.lineThrough,
    );

    reply.complete(
      skir.DeclineOrganizationJoinRequestsResponse.serializer.toBytes(
        skir.DeclineOrganizationJoinRequestsResponse.createRequestNotFoundError(
          requestIds: [_request.requestId],
        ),
      ),
    );
    await panel.eventually(
      () => expect(panel.messageUnder("Grace"), isNotNull),
    );
    await panel.settle();
    expect(panel.onPage("Grace"), findsOneWidget);
    expect(
      tester.textDecorationOf(panel.onPage("Grace")),
      isNot(TextDecoration.lineThrough),
    );
    expect(panel.messageUnder("Grace"), "Request not found");
  });

  testWidgets("the inspector offers Accept once a role to grant is chosen, "
      "and Accept adds the member", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membershipService(roles: [_editor], joinRequests: [_request]),
    ], at: membersPage(const JoinRequestsRoute()));

    await panel.item("Grace").select();
    expect(panel.inspector.heading("Roles to grant"), findsOneWidget);
    expect(panel.inspector.operations, isNot(contains("Accept")));

    await panel.tapOn(
      find.descendant(
        of: find.byType(JoinRequestInspection),
        matching: find.text("Editor"),
      ),
    );
    await panel.inspector.run("Accept");

    await panel.eventually(() => expect(panel.onPage("Grace"), findsNothing));
  });

  testWidgets("two selected requests are accepted together, each with the "
      "roles chosen for both", (tester) async {
    final erin = joinRequest("erin", name: "Erin");
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membershipService(roles: [_editor], joinRequests: [_request, erin]),
    ], at: membersPage(const JoinRequestsRoute()));

    await panel.item("Grace").toggle();
    await panel.item("Erin").toggle();
    expect(panel.inspector.heading("2 join requests"), findsOneWidget);
    await panel.tapOn(
      find.descendant(
        of: find.byType(JoinRequestInspection),
        matching: find.text("Editor"),
      ),
    );
    await panel.inspector.run("Accept 2");

    await panel.eventually(() {
      expect(panel.onPage("Grace"), findsNothing);
      expect(panel.onPage("Erin"), findsNothing);
    });
  });
}
