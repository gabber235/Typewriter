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
  for (final (name, share, declines) in [
    ("holding Delete on the selected request declines it", 1.0, 1),
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
        return skir.DeclineOrganizationJoinRequestsResponse.serializer.toBytes(
          skir.DeclineOrganizationJoinRequestsResponse.createRequestNotFoundError(
            requestIds: [_request.requestId],
          ),
        );
      });
      await panel.eventually(() => expect(panel.shows("Grace"), isTrue));
      // The page opens on the first request.
      expect(panel.focused, contains("Grace"));
      await panel.press(LogicalKeyboardKey.enter);

      await panel.holdKey(LogicalKeyboardKey.delete, share: share);

      expect(sent, declines);
      expect(panel.dialog.showing("Decline Grace's request?"), isFalse);
    });
  }
}
