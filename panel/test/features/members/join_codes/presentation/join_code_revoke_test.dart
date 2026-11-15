import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _revokeOne = "Revoke this join code? Nobody new can join with it.";

void main() {
  testWidgets("a held revoke keeps the code listed while it sends, and a "
      "refusal leaves it listed with the refusal under it", (tester) async {
    final code = skir.JoinCode(
      code: skir.recordId("join_code:abc123"),
      createdAt: DateTime.utc(2026),
      expiresAt: null,
      singleUse: true,
      autoAccept: skir.JoinCode_AutoAccept(roleIds: const []),
    );
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membershipBackend(joinCodes: [code]),
    ], at: membersPage(const JoinCodesRoute()));
    final reply = Completer<Uint8List>();
    panel.world.nats.registerHandler(
      "cloud.to.user.ada.organization.acme.members.join_codes.revoke",
      (_) => reply.future,
    );

    await panel.item(joinCodeUrl(code.code)).select();
    final gesture = await tester.startGesture(
      tester.getCenter(
        find.bySemanticsLabel(RegExp(RegExp.escape(_revokeOne))).last,
      ),
    );
    await panel.holdFor(1);
    await gesture.up();
    await tester.pump();
    expect(panel.shows("No active join codes"), isFalse);

    reply.complete(
      skir.RevokeOrganizationJoinCodesResponse.serializer.toBytes(
        skir.RevokeOrganizationJoinCodesResponse.createCodeNotFoundError(
          codeIds: [code.code],
        ),
      ),
    );
    await panel.eventually(
      () => expect(
        find.descendant(
          of: find.byType(HoldRow),
          matching: find.byType(LabeledMessage),
        ),
        findsOneWidget,
      ),
    );
    await panel.settle();
    expect(panel.shows("No active join codes"), isFalse);
  });

  testWidgets("a revoked join code no longer shows on the new join code "
      "card", (tester) async {
    final clipboard = tester.recordClipboard();
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membershipService(),
    ], at: membersPage(const JoinCodesRoute()));

    await panel.tapOn(find.text("Generate Join Code"));
    await panel.eventually(() => expect(clipboard, hasLength(1)));
    final link = clipboard.single;
    await panel.eventually(() => expect(panel.reads(link), isTrue));

    await panel.item(link).select();
    await panel.holdButton(_revokeOne);

    await panel.eventually(
      () => expect(panel.shows("No active join codes"), isTrue),
    );
    expect(panel.reads(link), isFalse);
    expect(find.text("Copy Join Code"), findsNothing);
  });

  group("two selected codes are revoked together", () {
    final first = joinCode("first");
    final second = joinCode("second");
    final third = joinCode("third");
    final page = [
      signedIn(ada, organization: acme),
      membershipService(joinCodes: [first, second, third]),
    ];

    testWidgets("with the keyboard alone, by holding Delete", (tester) async {
      final panel = await tester.pumpPanel(
        page,
        at: membersPage(const JoinCodesRoute()),
      );

      await panel.press(LogicalKeyboardKey.space);
      await panel.press(LogicalKeyboardKey.keyJ);
      await panel.press(LogicalKeyboardKey.space);
      expect(panel.inspector.heading("2 join codes"), findsOneWidget);
      await panel.holdKey(LogicalKeyboardKey.delete);

      await panel.eventually(() {
        expect(find.textContaining(first.code.id), findsNothing);
        expect(find.textContaining(second.code.id), findsNothing);
      });
      expect(find.textContaining(third.code.id), findsWidgets);
    });

    testWidgets("with the mouse alone, by holding Revoke in the inspector", (
      tester,
    ) async {
      final panel = await tester.pumpPanel(
        page,
        at: membersPage(const JoinCodesRoute()),
      );

      await panel.item(joinCodeUrl(first.code)).toggle();
      await panel.item(joinCodeUrl(second.code)).toggle();
      await panel.holdButton("Revoke 2 join codes?");

      await panel.eventually(() {
        expect(find.textContaining(first.code.id), findsNothing);
        expect(find.textContaining(second.code.id), findsNothing);
      });
      expect(find.textContaining(third.code.id), findsWidgets);
    });
  });

  testWidgets("a refused revoke keeps every selected code selected, so it "
      "can be tried again", (tester) async {
    final first = joinCode("first");
    final second = joinCode("second");
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membershipBackend(joinCodes: [first, second]),
    ], at: membersPage(const JoinCodesRoute()));
    panel.world.nats.registerHandler(
      "cloud.to.user.ada.organization.acme.members.join_codes.revoke",
      (_) => skir.RevokeOrganizationJoinCodesResponse.serializer.toBytes(
        skir.RevokeOrganizationJoinCodesResponse.createCodeNotFoundError(
          codeIds: [first.code],
        ),
      ),
    );

    await panel.item(joinCodeUrl(first.code)).toggle();
    await panel.item(joinCodeUrl(second.code)).toggle();
    await panel.holdButton("Revoke 2 join codes?");
    await panel.eventually(
      () => expect(
        find.descendant(
          of: find.byType(HoldRow),
          matching: find.byType(LabeledMessage),
        ),
        findsNWidgets(2),
      ),
    );
    await panel.settle();

    expect(panel.inspector.heading("2 join codes"), findsOneWidget);
    expect(panel.item(joinCodeUrl(first.code)).isChecked, isTrue);
    expect(panel.item(joinCodeUrl(second.code)).isChecked, isTrue);
  });

  testWidgets("the inspector copies the selected join code", (tester) async {
    final clipboard = tester.recordClipboard();
    final code = joinCode("spring");
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membershipService(joinCodes: [code]),
    ], at: membersPage(const JoinCodesRoute()));

    await panel.item(joinCodeUrl(code.code)).select();
    await panel.tapOn(
      find.descendant(
        of: find.byType(JoinCodeInspection),
        matching: find.text("Copy Join Code"),
      ),
    );

    expect(clipboard, [joinCodeUrl(code.code)]);
  });
}
