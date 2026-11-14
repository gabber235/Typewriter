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
      skir.RevokeOrganizationJoinCodeResponse.serializer.toBytes(
        skir.RevokeOrganizationJoinCodeResponse.createCodeNotFoundError(
          codeId: code.code,
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

    await panel.holdButton(_revokeOne);

    await panel.eventually(
      () => expect(panel.shows("No active join codes"), isTrue),
    );
    expect(panel.reads(link), isFalse);
    expect(find.text("Copy Join Code"), findsNothing);
  });
}
