import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final globex = organization("Globex");

  test("work started before sign in resolves is listed once it did", () async {
    final world = testWorld([signedIn(ada, organization: acme)]);
    final container = world.container;
    // The panel shell watches local work for as long as it is open.
    final work = (container..listen(localWorkProvider, (_, _) {})).read(
      localWorkControllerProvider,
    );

    await container.read(userIdProvider.future);
    await container.pump();
    textEditorTarget(
          "resource",
          label: "Draft",
          scope: EditorResourceScope(organizationId: acme.organizationId),
        )
        .acquire(work)
        .update(editorRootPath, skir.DataValue.wrapStringValue("Draft"));

    await eventually(
      () => expect(
        [
          for (final entry in container.read(localWorkProvider).entries.values)
            entry.label,
        ],
        ["Draft"],
      ),
    );
  });

  const leaveQuestion = "Leave this work session?";

  testWidgets(
    "leaving the realm keeps drafts and switching organization drops them",
    (tester) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme, others: [globex]),
        realm(),
      ]);
      final work = panel.container.read(localWorkControllerProvider);
      final realmScope = panel.world.requireRealm.scope;
      final source =
          textEditorTarget(
              "resource",
              label: "Draft",
              scope: EditorResourceScope(
                organizationId: realmScope.organizationId,
                realmId: realmScope.realmId,
              ),
            ).acquire(work)
            ..update(editorRootPath, skir.DataValue.wrapStringValue("Draft"));

      await panel.follow(
        OrganizationRoute(organizationId: acme.organizationId.id),
      );
      expect(
        [
          for (final entry
              in panel.container.read(localWorkProvider).entries.values)
            entry.label,
        ],
        ["Draft"],
      );
      expect(
        source.value(editorRootPath).valueOrNull,
        skir.DataValue.wrapStringValue("Draft"),
      );

      await panel.follow(
        OrganizationRoute(organizationId: globex.organizationId.id),
      );
      await panel.dialog.choose("Leave", message: leaveQuestion);
      expect(panel.path, contains("globex"));
      expect([
        for (final entry
            in panel.container.read(localWorkProvider).entries.values)
          entry.label,
      ], isEmpty);
      expect(await source.flush(), isA<MutationUnavailable>());
    },
  );

  testWidgets(
    "switching organization forgets a sent request and ignores its late "
    "response",
    (tester) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme, others: [globex]),
        realm(),
      ]);
      final work = panel.container.read(localWorkControllerProvider);
      final response = Completer<SubmissionResult<String>>();
      final sent = Completer<void>();
      var integrations = 0;
      final submission = work.start(
        PreparedCommit<String>(
          id: "sent",
          label: "Sent request",
          send: () {
            sent.complete();
            return response.future;
          },
          integrate: (_) async => integrations++,
        ),
      );
      final result = submission.run();
      await sent.future;

      await panel.follow(
        OrganizationRoute(organizationId: globex.organizationId.id),
      );
      expect(panel.container.read(localWorkProvider).submissions, isEmpty);
      response.complete(const SubmissionConfirmed("Applied remotely"));
      expect(await result, isA<SubmissionConfirmed<String>>());
      expect(integrations, 0);
      expect(submission.run, throwsStateError);
    },
  );

  testWidgets(
    "switching organization forgets uncertain requests and disables their "
    "replay",
    (tester) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme, others: [globex]),
        realm(),
      ]);
      final work = panel.container.read(localWorkControllerProvider);
      final submission = work.start(
        PreparedCommit<String>(
          id: "uncertain",
          label: "Uncertain request",
          replay: SubmissionReplay.identicalRequest,
          send: () async => SubmissionUncertain(
            message: "Lost response",
            cause: TimeoutException("Lost response"),
            stackTrace: StackTrace.current,
          ),
        ),
      );
      expect(await submission.run(), isA<SubmissionUncertain<String>>());

      await panel.follow(
        OrganizationRoute(organizationId: globex.organizationId.id),
      );
      expect(panel.container.read(localWorkProvider).submissions, isEmpty);
      expect(submission.run, throwsStateError);
    },
  );
}
