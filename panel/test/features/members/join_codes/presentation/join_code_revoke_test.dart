import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("a revoked join code is hidden while the revocation sends and "
      "comes back when the backend refuses it", (tester) async {
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
    expect(panel.shows("No active join codes"), isFalse);

    await panel.tapOn(find.tooltip("Revoke join code"));
    // The revocation keeps the panel busy until the reply below, so the
    // next steps wait for what they need instead of settling.
    const question = "Revoke this join code?";
    final dialog = find.semantics
        .byPredicate((node) => node.spoken.contains(question))
        .evaluate()
        .last
        .route!;
    await tester.tapAt(dialog.button("Revoke").screenRect.center);

    await panel.eventually(
      () => expect(panel.shows("No active join codes"), isTrue),
    );

    reply.complete(
      skir.RevokeOrganizationJoinCodeResponse.serializer.toBytes(
        skir.RevokeOrganizationJoinCodeResponse.createCodeNotFoundError(
          codeId: code.code,
        ),
      ),
    );
    await panel.eventually(
      () => expect(panel.shows("No active join codes"), isFalse),
    );
    await panel.settle();
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

    await panel.tapOn(find.tooltip("Revoke join code"));
    await panel.dialog.choose("Revoke", message: "Revoke this join code?");

    await panel.eventually(
      () => expect(panel.shows("No active join codes"), isTrue),
    );
    expect(panel.reads(link), isFalse);
    expect(find.text("Copy Join Code"), findsNothing);
  });
}
