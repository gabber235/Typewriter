import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  for (final (key, invoked) in [
    (LogicalKeyboardKey.escape, "clear"),
    (LogicalKeyboardKey.delete, "decline"),
  ]) {
    testWidgets("${key.keyLabel} in the bulk join request actions invokes "
        "$invoked", (tester) async {
      final calls = <String>[];
      final panel = await tester.pumpPanel(
        [signedIn(ada, organization: acme), membership()],
        at: PanelLocation.component(
          BulkJoinRequestActions(
            selectedCount: 1,
            selectedIds: {skir.recordId("request_to_join:request")},
            onClearSelection: () => calls.add("clear"),
            onDecline: () async => calls.add("decline"),
          ),
        ),
      );
      await panel.press(LogicalKeyboardKey.tab);

      await panel.press(key);

      expect(calls, [invoked]);
    });
  }

  testWidgets("Delete on a selected join request declines the whole "
      "selection without asking", (tester) async {
    var bulkDeclines = 0;
    final request = skir.OrganizationJoinRequest(
      requestId: skir.recordId("request_to_join:selected"),
      userId: skir.recordId("user:selected"),
      userName: "Selected",
      userEmail: "selected@example.com",
      requestedAt: DateTime.utc(2026),
      expiresAt: DateTime.utc(2100),
      userAvatarUrl: null,
    );
    final panel = await tester.pumpPanel(
      [
        signedIn(ada, organization: acme),
        membership(joinRequests: [request]),
      ],
      at: PanelLocation.component(
        JoinRequestCard(
          request: request,
          isSelected: true,
          onSelectionChanged: (_) {},
          onSelectAll: () {},
          onClearSelection: () {},
          hasSelection: true,
          onDeclineSelection: () async => bulkDeclines++,
        ),
      ),
    );
    await panel.press(LogicalKeyboardKey.tab);

    await panel.press(LogicalKeyboardKey.delete);

    expect(bulkDeclines, 1);
    expect(panel.dialog.showing("Decline Selected's request?"), isFalse);
  });
}
