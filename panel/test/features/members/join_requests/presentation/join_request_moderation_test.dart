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

    final gesture = await tester.startGesture(
      tester.getCenter(find.bySemanticsLabel(RegExp(r"^Decline Grace\?")).last),
    );
    await panel.holdFor(1);
    await gesture.up();
    await tester.pump();

    expect(find.text("Grace"), findsOneWidget);
    expect(
      tester.textDecorationOf(find.text("Grace")),
      TextDecoration.lineThrough,
    );

    reply.complete(
      skir.DeclineOrganizationJoinRequestResponse.serializer.toBytes(
        skir.DeclineOrganizationJoinRequestResponse.createRequestNotFoundError(
          requestId: _request.requestId,
        ),
      ),
    );
    await panel.eventually(
      () => expect(panel.messageUnder("Grace"), isNotNull),
    );
    await panel.settle();
    expect(find.text("Grace"), findsOneWidget);
    expect(
      tester.textDecorationOf(find.text("Grace")),
      isNot(TextDecoration.lineThrough),
    );
    expect(panel.messageUnder("Grace"), "Request not found");
  });

  testWidgets("a request cannot be approved until a role is chosen", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membership(roles: [_editor], joinRequests: [_request]),
    ], at: membersPage(const JoinRequestsRoute()));

    await panel.tapOn(
      // The card's own button; the focused card also lists it in the
      // action row.
      find.descendant(
        of: find.byType(JoinRequestCard),
        matching: find.text("Accept"),
      ),
    );

    expect(semanticsLabeled("Confirm & Add Member").single.isEnabled, isFalse);

    await panel.tapOn(find.text("Editor"));

    expect(semanticsLabeled("Confirm & Add Member").single.isEnabled, isTrue);
  });
}
