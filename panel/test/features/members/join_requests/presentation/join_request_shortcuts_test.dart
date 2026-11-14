import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _declineSubject =
    "cloud.to.user.ada.organization.acme.members.join_requests.decline";

final _request = joinRequest(
  "grace",
  name: "Grace",
  email: "grace@typewriter.test",
);

void main() {
  testWidgets("Escape in the bulk join request actions clears the "
      "selection", (tester) async {
    final calls = <String>[];
    final panel = await tester.pumpPanel(
      [signedIn(ada, organization: acme), membership()],
      at: PanelLocation.component(
        HookBuilder(
          builder: (context) {
            final rows = useAnimatedRows(
              items: const <skir.OrganizationJoinRequest>[],
              identity: (request) => request.requestId,
            );
            return BulkJoinRequestActions(
              selectedCount: 1,
              selectedIds: {_request.requestId},
              onClearSelection: () => calls.add("clear"),
              decline: joinRequestDecline(
                id: "decline_bulk",
                label: "Decline requests",
                priority: 2,
                targets: () => {_request.requestId},
                nameOf: (_) => "Grace",
                rows: rows,
              ),
            );
          },
        ),
      ),
    );
    await panel.press(LogicalKeyboardKey.tab);

    await panel.press(LogicalKeyboardKey.escape);

    expect(calls, ["clear"]);
  });

  for (final (name, share, declines) in [
    ("holding Delete on the focused request declines it", 1.0, 1),
    ("releasing Delete early keeps the request", 0.5, 0),
  ]) {
    testWidgets(name, (tester) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        membershipBackend(joinRequests: [_request]),
      ], at: membersPage(const JoinRequestsRoute()));
      var sent = 0;
      panel.world.nats.registerHandler(_declineSubject, (_) {
        sent++;
        return skir.DeclineOrganizationJoinRequestResponse.serializer.toBytes(
          skir.DeclineOrganizationJoinRequestResponse.createRequestNotFoundError(
            requestId: _request.requestId,
          ),
        );
      });
      await panel.eventually(() => expect(panel.shows("Grace"), isTrue));
      // The page opens on the first request.
      expect(panel.focused, contains("Grace"));

      await panel.holdKey(LogicalKeyboardKey.delete, share: share);

      expect(sent, declines);
      expect(panel.dialog.showing("Decline Grace's request?"), isFalse);
    });
  }
}
