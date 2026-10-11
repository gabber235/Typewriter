import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../support/editor_fixture.dart";

const _key = EditorResourceKey(scope: "org1", identity: "resource");
final _title = editorRootPath.field("title");
final _description = editorRootPath.field("description");
ValueEditingRegistration _target({
  required EditorCommitter commit,
  int revision = 1,
  String description = "Original description",
  EditorCommitPolicy policy = EditorCommitPolicy.applyResource,
  List<EditorDiagnostic> Function(skir.DataValue)? validateDraft,
}) => fakeEditorTarget(
  targetId: _key.identity,
  scope: _key.scope,
  label: "Resource",
  document: recordEditorDocument(
    {
      "title": skir.DataValue.wrapStringValue("Original"),
      "description": skir.DataValue.wrapStringValue(description),
    },
    {
      "title": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
      "description": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
    },
    revision,
  ),
  validation: acceptTestEditorMutation,
  commitPolicy: policy,
  validateDraft: validateDraft,
  commit: commit,
);

void main() {
  test("incompatible replacement stays pending across a host rebuild", () {
    final workspace = ScopedWorkSession();
    addTearDown(workspace.dispose);
    final source = _contractTarget("one", 1, "Remote one").acquire(workspace);
    addTearDown(
      workspace.lease(WorkDriverId(domain: "value", scope: _key)).release,
    );
    source.update(_title, skir.DataValue.wrapStringValue("Draft"));

    final rebuilt = _contractTarget("two", 2, "Remote two").acquire(workspace);

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
    final source = _contractTarget("one", 1, "Remote one").acquire(workspace);
    addTearDown(
      workspace.lease(WorkDriverId(domain: "value", scope: _key)).release,
    );
    source.update(_title, skir.DataValue.wrapStringValue("Draft"));
    _contractTarget("two", 2, "Remote two").acquire(workspace);

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
    final target = _contractTarget("one", 1, "Remote one");
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

    resource.load = () async => _ContractSnapshot(
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
      final source = _target(
        commit: (commit) async {
          oldSends++;
          return MutationSuccess(revision: 2, value: commit.rootValue);
        },
      ).acquire(workspace);

      addTearDown(
        workspace.lease(WorkDriverId(domain: "value", scope: _key)).release,
      );
      source.update(_title, skir.DataValue.wrapStringValue("Draft"));
      final replacement = _target(
        revision: 2,
        description: "Remote description",
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

      expect(await source.flush(), isA<MutationInvalid>());
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
    final source = _target(
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
    _target(
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
    _target(commit: commit).acquire(workspace);
    expect(
      () => _target(
        commit: commit,
        policy: EditorCommitPolicy.autosaveChanges,
      ).acquire(workspace),
      throwsStateError,
    );
    expect(
      _target(commit: commit).acquire(workspace).commitPolicy,
      EditorCommitPolicy.applyResource,
    );
  });
}

ValueEditingRegistration _contractTarget(
  String contract,
  int revision,
  String description,
) {
  final snapshot = _ContractSnapshot(
    contract,
    recordEditorDocument(
      {
        "title": skir.DataValue.wrapStringValue("Original"),
        "description": skir.DataValue.wrapStringValue(description),
      },
      {
        "title": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
        "description": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
      },
      revision,
    ),
  );
  return ValueEditingRegistration(
    targetId: _key.identity,
    label: "Resource",
    persistence: ScriptedValuePersistence(
      key: _key,
      current: snapshot,
      commit: (commit) async => MutationSuccess(
        revision: commit.expectedRevision + 1,
        value: commit.rootValue,
      ),
    ),
    snapshot: snapshot,
    commitPolicy: EditorCommitPolicy.applyResource,
  );
}

final class _ContractSnapshot extends EditorSnapshot
    implements EditorContractSnapshot {
  const _ContractSnapshot(this.contract, this.document);

  final String contract;
  @override
  final EditorDocument document;

  @override
  bool contractCompatibleWith(EditorSnapshot candidate) =>
      candidate is _ContractSnapshot && candidate.contract == contract;

  @override
  EditorMutationResult validate(skir.ValuePath path, skir.DataValue value) =>
      acceptTestEditorMutation(path, value);
}
