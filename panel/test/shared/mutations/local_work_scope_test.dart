import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

skir.RecordId _id(String table, String key) =>
    skir.RecordId(table: table, key: skir.RecordIdKey.wrapString(key));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("controller remains valid when authentication becomes ready", () async {
    final user = Completer<String?>();
    final organization = _id("organization", "first");
    final container = ProviderContainer.test(
      overrides: [
        userIdProvider.overrideWith((ref) => user.future),
        organizationIdProvider.overrideWith((ref) => organization),
      ],
    );
    final controller = container.read(localWorkControllerProvider);

    user.complete("user");
    await container.read(userIdProvider.future);
    await container.pump();

    expect(container.read(localWorkControllerProvider), same(controller));
    expect(
      () => controller.editor(
        fakeEditorTarget(
          targetId: "resource",
          label: "Resource",
          scope: EditorResourceScope(organizationId: organization),
          document: const EditorDocument(
            rootType: StringType(),
            typeCatalog: TypeCatalog([]),
            confirmedValue: StringValue("Original"),
            revision: 1,
          ),
          validation: acceptTestEditorMutation,
          commit: (_) async => throw StateError("No save expected"),
        ),
      ),
      returnsNormally,
    );
  });

  late ProviderContainer container;
  late skir.RecordId organization;
  late skir.RecordId realm;

  setUp(() async {
    organization = _id("organization", "first");
    realm = _id("realm", "first");
    container = ProviderContainer.test(
      overrides: [
        userIdProvider.overrideWith((ref) async => "user"),
        organizationIdProvider.overrideWith((ref) => organization),
        realmIdProvider.overrideWith((ref) => realm),
      ],
    );
    await container.read(userIdProvider.future);
  });

  Future<void> switchOrganization() async {
    organization = _id("organization", "second");
    container.invalidate(organizationIdProvider);
    await container.pump();
  }

  test(
    "realm navigation retains drafts and organization navigation drops them",
    () async {
      final workspace = container.read(localWorkControllerProvider);
      final target = fakeEditorTarget(
        targetId: "resource",
        label: "Draft",
        scope: EditorResourceScope(
          organizationId: organization,
          realmId: realm,
        ),
        document: const EditorDocument(
          rootType: StringType(),
          typeCatalog: TypeCatalog([]),
          confirmedValue: StringValue("Original"),
          revision: 1,
        ),
        validation: acceptTestEditorMutation,
        commitPolicy: EditorCommitPolicy.applyResource,
        commit: (_) async => throw StateError("No save expected"),
      );
      final source = workspace.editor(target)
        ..update(DataPath.root, const StringValue("Draft"));

      realm = _id("realm", "second");
      container.invalidate(realmIdProvider);
      await container.pump();
      expect(container.read(localWorkControllerProvider), same(workspace));
      expect(
        source.value(DataPath.root).valueOrNull,
        const StringValue("Draft"),
      );

      await switchOrganization();
      final next = container.read(localWorkControllerProvider);
      expect(next, same(workspace));
      final nextState = container.read(localWorkProvider);
      expect(nextState.resources, isEmpty);
      expect(workspace.resources, isEmpty);
      expect(await source.flush(), isA<MutationUnavailable>());
    },
  );

  test(
    "switching forgets a sent request and ignores its late response",
    () async {
      final workspace = container.read(localWorkControllerProvider);
      final response = Completer<SubmissionResult<String>>();
      final sent = Completer<void>();
      var integrations = 0;
      final submission = workspace.start(
        PreparedCommit<String>(
          id: "sent",
          label: "Sent request",
          send: () {
            sent.complete();
            return response.future;
          },
          integrate: (_) async {
            integrations++;
          },
        ),
      );
      final result = submission.run();

      await sent.future;

      await switchOrganization();
      expect(container.read(localWorkProvider).submissions, isEmpty);
      expect(workspace.submissions, isEmpty);
      response.complete(const SubmissionConfirmed("Applied remotely"));
      expect(await result, isA<SubmissionConfirmed<String>>());
      expect(integrations, 0);

      expect(submission.run, throwsStateError);
    },
  );

  test(
    "switching forgets uncertain requests and disables their replay",
    () async {
      final workspace = container.read(localWorkControllerProvider);
      final submission = workspace.start(
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

      await switchOrganization();
      expect(container.read(localWorkProvider).submissions, isEmpty);
      expect(workspace.submissions, isEmpty);
      expect(submission.run, throwsStateError);
    },
  );
}
