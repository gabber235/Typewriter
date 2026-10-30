import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _key = EditorResourceKey(scope: "org1", identity: "resource");
final _title = editorRootPath.field("title");
final _description = editorRootPath.field("description");
final _fields = {
  "title": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
  "description": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
};

void main() {
  test("incompatible replacement stays pending across a host rebuild", () {
    final workspace = ScopedWorkSession();
    addTearDown(workspace.dispose);
    final source = fakeEditorTarget(
      targetId: _key.identity,
      scope: _key.scope,
      label: "Resource",
      contract: "one",
      document: recordEditorDocument(
        {
          "title": skir.DataValue.wrapStringValue("Original"),
          "description": skir.DataValue.wrapStringValue("Remote one"),
        },
        _fields,
        1,
      ),
      commitPolicy: EditorCommitPolicy.applyResource,
      commit: (commit) async => MutationSuccess(
        revision: commit.expectedRevision + 1,
        value: commit.rootValue,
      ),
    ).acquire(workspace);
    addTearDown(
      workspace.lease(WorkDriverId(domain: "value", scope: _key)).release,
    );
    source.update(_title, skir.DataValue.wrapStringValue("Draft"));

    final rebuilt = fakeEditorTarget(
      targetId: _key.identity,
      scope: _key.scope,
      label: "Resource",
      contract: "two",
      document: recordEditorDocument(
        {
          "title": skir.DataValue.wrapStringValue("Original"),
          "description": skir.DataValue.wrapStringValue("Remote two"),
        },
        _fields,
        2,
      ),
      commitPolicy: EditorCommitPolicy.applyResource,
      commit: (commit) async => MutationSuccess(
        revision: commit.expectedRevision + 1,
        value: commit.rootValue,
      ),
    ).acquire(workspace);

    expect(rebuilt.workspace, same(source.workspace));
    expect(source.contractReconciliationPending, isTrue);
    expect(source.readOnly, isTrue);
    expect(
      source.value(_title).valueOrNull,
      skir.DataValue.wrapStringValue("Draft"),
    );
    expect(
      source.value(_description).valueOrNull,
      skir.DataValue.wrapStringValue("Remote one"),
    );

    expect(source.reconcilePendingContract(), isTrue);
    expect(source.contractReconciliationPending, isFalse);
    expect(source.readOnly, isFalse);
    expect(
      source.value(_title).valueOrNull,
      skir.DataValue.wrapStringValue("Draft"),
    );
    expect(
      source.value(_description).valueOrNull,
      skir.DataValue.wrapStringValue("Remote two"),
    );
  });

  test("discard accepts an incompatible replacement explicitly", () {
    final workspace = ScopedWorkSession();
    addTearDown(workspace.dispose);
    final source = fakeEditorTarget(
      targetId: _key.identity,
      scope: _key.scope,
      label: "Resource",
      contract: "one",
      document: recordEditorDocument(
        {
          "title": skir.DataValue.wrapStringValue("Original"),
          "description": skir.DataValue.wrapStringValue("Remote one"),
        },
        _fields,
        1,
      ),
      commitPolicy: EditorCommitPolicy.applyResource,
      commit: (commit) async => MutationSuccess(
        revision: commit.expectedRevision + 1,
        value: commit.rootValue,
      ),
    ).acquire(workspace);
    addTearDown(
      workspace.lease(WorkDriverId(domain: "value", scope: _key)).release,
    );
    source.update(_title, skir.DataValue.wrapStringValue("Draft"));
    fakeEditorTarget(
      targetId: _key.identity,
      scope: _key.scope,
      label: "Resource",
      contract: "two",
      document: recordEditorDocument(
        {
          "title": skir.DataValue.wrapStringValue("Original"),
          "description": skir.DataValue.wrapStringValue("Remote two"),
        },
        _fields,
        2,
      ),
      commitPolicy: EditorCommitPolicy.applyResource,
      commit: (commit) async => MutationSuccess(
        revision: commit.expectedRevision + 1,
        value: commit.rootValue,
      ),
    ).acquire(workspace);

    expect(source.discardDraftAndAcceptPendingContract(), isTrue);
    expect(source.hasWork, isFalse);
    expect(
      source.value(_title).valueOrNull,
      skir.DataValue.wrapStringValue("Original"),
    );
    expect(
      source.value(_description).valueOrNull,
      skir.DataValue.wrapStringValue("Remote two"),
    );
  });

  test("unavailable contract preserves draft until retry succeeds", () async {
    final workspace = ScopedWorkSession();
    addTearDown(workspace.dispose);
    final target = fakeEditorTarget(
      targetId: _key.identity,
      scope: _key.scope,
      label: "Resource",
      contract: "one",
      document: recordEditorDocument(
        {
          "title": skir.DataValue.wrapStringValue("Original"),
          "description": skir.DataValue.wrapStringValue("Remote one"),
        },
        _fields,
        1,
      ),
      commitPolicy: EditorCommitPolicy.applyResource,
      commit: (commit) async => MutationSuccess(
        revision: commit.expectedRevision + 1,
        value: commit.rootValue,
      ),
    );
    final resource = target.persistence as ScriptedValuePersistence;
    final source = target.acquire(workspace);
    addTearDown(
      workspace.lease(WorkDriverId(domain: "value", scope: _key)).release,
    );
    source
      ..update(_title, skir.DataValue.wrapStringValue("Draft"))
      ..markContractUnavailable("Catalog unavailable");

    expect(source.contractUnavailable, isTrue);
    expect(source.readOnly, isTrue);
    expect(
      source.value(_title).valueOrNull,
      skir.DataValue.wrapStringValue("Draft"),
    );

    resource.load = () async => FakeContractEditorSnapshot(
      "one",
      source.document.copyWith(revision: 2, readOnly: false, diagnostics: []),
    );
    expect(await source.retryContractRefresh(), isTrue);
    expect(source.contractUnavailable, isFalse);
    expect(source.readOnly, isFalse);
    expect(
      source.value(_title).valueOrNull,
      skir.DataValue.wrapStringValue("Draft"),
    );
  });

  test(
    "replacement preserves drafts and uses current validation and commit",
    () async {
      final workspace = ScopedWorkSession();
      addTearDown(workspace.dispose);
      var oldSends = 0;
      var newSends = 0;
      var reject = true;
      final source = fakeEditorTarget(
        targetId: _key.identity,
        scope: _key.scope,
        label: "Resource",
        document: recordEditorDocument(
          {
            "title": skir.DataValue.wrapStringValue("Original"),
            "description": skir.DataValue.wrapStringValue(
              "Original description",
            ),
          },
          _fields,
          1,
        ),
        commitPolicy: EditorCommitPolicy.applyResource,
        commit: (commit) async {
          oldSends++;
          return MutationSuccess(revision: 2, value: commit.rootValue);
        },
      ).acquire(workspace);

      addTearDown(
        workspace.lease(WorkDriverId(domain: "value", scope: _key)).release,
      );
      source.update(_title, skir.DataValue.wrapStringValue("Draft"));
      final replacement = fakeEditorTarget(
        targetId: _key.identity,
        scope: _key.scope,
        label: "Resource",
        document: recordEditorDocument(
          {
            "title": skir.DataValue.wrapStringValue("Original"),
            "description": skir.DataValue.wrapStringValue("Remote description"),
          },
          _fields,
          2,
        ),
        commitPolicy: EditorCommitPolicy.applyResource,
        validateDraft: (_) => reject
            ? [
                const EditorDiagnostic(
                  code: EditorDiagnosticCode.invalidValue,
                  message: "Current validation",
                ),
              ]
            : [],
        commit: (commit) async {
          newSends++;
          expect(commit.expectedRevision, 2);
          return MutationSuccess(revision: 3, value: commit.rootValue);
        },
      ).acquire(workspace);
      expect(replacement.workspace, same(source.workspace));
      expect(
        source.value(_title).valueOrNull,
        skir.DataValue.wrapStringValue("Draft"),
      );
      expect(
        source.value(_description).valueOrNull,
        skir.DataValue.wrapStringValue("Remote description"),
      );

      expect(
        await source.flush(),
        isA<MutationInvalid>().having(
          (invalid) => [
            for (final diagnostic in invalid.diagnostics) diagnostic.message,
          ],
          "messages",
          ["Current validation"],
        ),
      );
      expect(newSends, 0);
      reject = false;
      expect(await source.flush(), isA<MutationSuccess>());
      expect(oldSends, 0);
      expect(newSends, 1);
    },
  );

  test("replacement does not retarget a running submission", () async {
    final workspace = ScopedWorkSession();
    addTearDown(workspace.dispose);
    final response = Completer<TypedMutationResult>();
    final sent = Completer<EditorCommit>();
    var newSends = 0;
    final source = fakeEditorTarget(
      targetId: _key.identity,
      scope: _key.scope,
      label: "Resource",
      document: recordEditorDocument(
        {
          "title": skir.DataValue.wrapStringValue("Original"),
          "description": skir.DataValue.wrapStringValue("Original description"),
        },
        _fields,
        1,
      ),
      commitPolicy: EditorCommitPolicy.applyResource,
      commit: (commit) {
        sent.complete(commit);
        return response.future;
      },
    ).acquire(workspace);

    addTearDown(
      workspace.lease(WorkDriverId(domain: "value", scope: _key)).release,
    );
    source.update(_title, skir.DataValue.wrapStringValue("First"));
    final pending = source.flush();
    final captured = await sent.future;
    fakeEditorTarget(
      targetId: _key.identity,
      scope: _key.scope,
      label: "Resource",
      document: recordEditorDocument(
        {
          "title": skir.DataValue.wrapStringValue("Original"),
          "description": skir.DataValue.wrapStringValue("Original description"),
        },
        _fields,
        1,
      ),
      commitPolicy: EditorCommitPolicy.applyResource,
      commit: (commit) async {
        newSends++;
        return MutationSuccess(revision: 3, value: commit.rootValue);
      },
    ).acquire(workspace);
    response.complete(MutationSuccess(revision: 2, value: captured.rootValue));

    expect(await pending, isA<MutationSuccess>());
    expect(newSends, 0);
    source.update(_title, skir.DataValue.wrapStringValue("Second"));
    expect(await source.flush(), isA<MutationSuccess>());
    expect(newSends, 1);
  });

  test("commit policy cannot change for an existing resource", () {
    final workspace = ScopedWorkSession();
    addTearDown(workspace.dispose);
    Future<TypedMutationResult> commit(EditorCommit commit) async =>
        MutationSuccess(revision: 2, value: commit.rootValue);
    fakeEditorTarget(
      targetId: _key.identity,
      scope: _key.scope,
      label: "Resource",
      document: recordEditorDocument(
        {
          "title": skir.DataValue.wrapStringValue("Original"),
          "description": skir.DataValue.wrapStringValue("Original description"),
        },
        _fields,
        1,
      ),
      commitPolicy: EditorCommitPolicy.applyResource,
      commit: commit,
    ).acquire(workspace);
    expect(
      () => fakeEditorTarget(
        targetId: _key.identity,
        scope: _key.scope,
        label: "Resource",
        document: recordEditorDocument(
          {
            "title": skir.DataValue.wrapStringValue("Original"),
            "description": skir.DataValue.wrapStringValue(
              "Original description",
            ),
          },
          _fields,
          1,
        ),
        commitPolicy: EditorCommitPolicy.autosaveChanges,
        commit: commit,
      ).acquire(workspace),
      throwsStateError,
    );
    expect(
      fakeEditorTarget(
        targetId: _key.identity,
        scope: _key.scope,
        label: "Resource",
        document: recordEditorDocument(
          {
            "title": skir.DataValue.wrapStringValue("Original"),
            "description": skir.DataValue.wrapStringValue(
              "Original description",
            ),
          },
          _fields,
          1,
        ),
        commitPolicy: EditorCommitPolicy.applyResource,
        commit: commit,
      ).acquire(workspace).commitPolicy,
      EditorCommitPolicy.applyResource,
    );
  });
}
