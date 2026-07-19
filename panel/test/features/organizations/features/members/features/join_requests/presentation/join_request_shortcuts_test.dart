import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_requests/application/join_requests.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_requests/presentation/join_request_actions.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_requests/presentation/join_request_card.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/converters.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

void main() {
  testWidgets("join request bulk shortcuts clear and decline selection", (
    tester,
  ) async {
    var clears = 0;
    var declines = 0;

    await tester.pumpWidget(
      FakeApp(
        overrides: organizationMembersProviderOverrides(
          state: DisplayState.noItems,
        ),
        child: BulkJoinRequestActions(
          selectedCount: 1,
          selectedIds: {recordId("request_to_join:request")},
          onClearSelection: () => clears++,
          onDecline: () async => declines++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, isNotNull);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(clears, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    expect(declines, 1);
  });

  testWidgets("selected request card routes decline to bulk callback", (
    tester,
  ) async {
    var bulkDeclines = 0;
    final request = OrganizationJoinRequest(
      requestId: recordId("request_to_join:selected"),
      userId: recordId("user:selected"),
      userName: "Selected",
      userEmail: "selected@example.com",
      requestedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );

    await tester.pumpWidget(
      FakeApp(
        child: JoinRequestCard(
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
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);

    expect(bulkDeclines, 1);
    expect(find.text("Decline join request?"), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
