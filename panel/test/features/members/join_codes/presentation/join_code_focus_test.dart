import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final first = joinCode("first");
  final second = joinCode("second");

  testWidgets("the join codes page opens on the first code", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membershipService(joinCodes: [first, second]),
    ], at: membersPage(const JoinCodesRoute()));
    expect(panel.focused, contains(first.code.id));
  });

  testWidgets("with no codes the page opens on Generate Join Code", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membershipService(joinCodes: const []),
    ], at: membersPage(const JoinCodesRoute()));
    expect(panel.hasFocusOn("Generate Join Code"), isTrue);
  });

  testWidgets("revoking the focused code by keys focuses the next code", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membershipService(joinCodes: [first, second]),
    ], at: membersPage(const JoinCodesRoute()));
    await panel.holdKey(LogicalKeyboardKey.delete);
    await panel.eventually(() => expect(panel.focusedRow, second));
  });

  testWidgets("revoking the last code from the inspector brings focus back "
      "to Generate Join Code", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membershipService(joinCodes: [first]),
    ], at: membersPage(const JoinCodesRoute()));
    await panel.press(LogicalKeyboardKey.space);
    await panel.pressControl(LogicalKeyboardKey.keyL);
    await panel.tabTo("Revoke this join code? Nobody new can join with it.");

    await panel.holdKey(LogicalKeyboardKey.enter);

    await panel.eventually(
      () => expect(panel.shows("No active join codes"), isTrue),
    );
    await panel.settle();
    expect(panel.hasFocusOn("Generate Join Code"), isTrue);
  });

  testWidgets("a generated code takes focus when it arrives", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membershipService(joinCodes: [first]),
    ], at: membersPage(const JoinCodesRoute()));
    await panel.activateWithKeyboard(find.text("Generate Join Code"));
    await panel.eventually(
      () => expect(panel.focusedRow, isA<skir.JoinCode>()),
    );
    await panel.eventually(() => expect(panel.focusedRow, isNot(first)));
    await panel.settle();
  });

  testWidgets("a code someone else generates leaves focus on the focused "
      "code", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membershipBackend(joinCodes: [first]),
    ], at: membersPage(const JoinCodesRoute()));
    await panel.eventually(() => expect(panel.focusedRow, first));
    panel.world.nats.announceJoinCodes(
      acme.organizationId,
      skir.OrganizationJoinCodesChanged(
        sequence: 2,
        changes: [skir.OrganizationJoinCodesChange.wrapAdd(second)],
      ),
    );
    await panel.settle();
    expect(find.textContaining(second.code.id), findsWidgets);
    expect(panel.focusedRow, first);
  });
}
