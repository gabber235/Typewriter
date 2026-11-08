import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/pump_panel.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";
import "package:typewriter_testkit/src/traits/organizations/user_backend.dart";
import "package:typewriter_testkit/src/traits/session.dart";

/// The join request of a signed in user still waiting for an answer.
extension PendingJoinRequest on WidgetTester {
  /// Pumps the panel of Ada with one pending request to join acme, shown as
  /// "Awaiting approval". [cancels] counts the cancels the backend received;
  /// each one succeeds and removes the request.
  Future<({PanelDriver panel, int Function() cancels})>
  pumpPendingJoinRequest() async {
    final pending = userJoinRequest(
      "acme",
      requestedAt: DateTime.utc(2026, 10, 26),
      expiresAt: DateTime.utc(2100),
    );
    final panel = await pumpPanel([
      signedIn(ada),
      userBackend(joinRequests: [pending]),
    ]);
    var cancels = 0;
    final subject = skir.CancelUserJoinRequestRequest(
      requestId: pending.requestId,
    ).operation(userId: ada.id).subject;
    panel.world.nats.registerHandler(subject, (_) {
      cancels++;
      return skir.CancelUserJoinRequestResponse.serializer.toBytes(
        skir.CancelUserJoinRequestResponse.createSuccess(
          event: skir.UserJoinRequestsChanged(
            sequence: 2,
            changes: [
              skir.UserJoinRequestsChange.wrapRemove(pending.requestId),
            ],
          ),
        ),
      );
    });
    await panel.eventually(
      () => expect(panel.shows("Awaiting approval"), isTrue),
    );
    return (panel: panel, cancels: () => cancels);
  }
}
