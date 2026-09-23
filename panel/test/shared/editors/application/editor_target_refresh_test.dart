import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

const _key = EditorResourceKey(scope: "org1", identity: "resource");
final _title = DataPath.root.field("title");
final _description = DataPath.root.field("description");
RecordValue _value(String title, String description) => RecordValue({
  "title": StringValue(title),
  "description": StringValue(description),
});
ResourceEditorTarget _target({
  required EditorCommitter commit,
  int revision = 1,
  String description = "Original description",
  EditorCommitPolicy policy = EditorCommitPolicy.applyResource,
  List<TypeDiagnostic> Function(DataValue)? validateDraft,
}) => fakeEditorTarget(
  targetId: _key.identity,
  scope: _key.scope,
  label: "Resource",
  document: EditorDocument(
    rootType: RecordType(
      fields: const {
        "title": TypeField(name: "title", type: StringType()),
        "description": TypeField(name: "description", type: StringType()),
      },
    ),
    typeCatalog: const TypeCatalog([]),
    confirmedValue: _value("Original", description),
    revision: revision,
  ),
  commitPolicy: policy,
  validateDraft: validateDraft,
  commit: commit,
);

void main() {
  test("incompatible replacement stays pending across a host rebuild", () {
    final workspace = LocalWorkSession();
    addTearDown(workspace.dispose);
    final source = workspace.editor(
      _contractTarget("one", 1, "Remote one"),
    ) as TransactionalEditorSource;
    workspace.retain(_key);
    source.update(_title, const StringValue("Draft"));

    final rebuilt = workspace.editor(_contractTarget("two", 2, "Remote two"));

    expect(rebuilt, same(source));
    expect(source.contractReconciliationPending, isTrue);
    expect(source.readOnly, isTrue);
    expect(source.value(_title).valueOrNull, const StringValue("Draft"));
    expect(
      source.value(_description).valueOrNull,
      const StringValue("Remote one"),
    );

    expect(source.reconcilePendingContract(), isTrue);
    expect(source.contractReconciliationPending, isFalse);
    expect(source.readOnly, isFalse);
    expect(source.value(_title).valueOrNull, const StringValue("Draft"));
    expect(
      source.value(_description).valueOrNull,
      const StringValue("Remote two"),
    );
  });

  test("discard accepts an incompatible replacement explicitly", () {
    final workspace = LocalWorkSession();
    addTearDown(workspace.dispose);
    final source = workspace.editor(
      _contractTarget("one", 1, "Remote one"),
    ) as TransactionalEditorSource;
    workspace.retain(_key);
    source.update(_title, const StringValue("Draft"));
    workspace.editor(_contractTarget("two", 2, "Remote two"));

    expect(source.discardDraftAndAcceptPendingContract(), isTrue);
    expect(source.hasWork, isFalse);
    expect(source.value(_title).valueOrNull, const StringValue("Original"));
    expect(
      source.value(_description).valueOrNull,
      const StringValue("Remote two"),
    );
  });

  test("unavailable contract preserves draft until retry succeeds", () async {
    final workspace = LocalWorkSession();
    addTearDown(workspace.dispose);
    final target = _contractTarget("one", 1, "Remote one");
    final resource = target.resource as FakeEditableResource;
    final source = workspace.editor(target) as TransactionalEditorSource;
    workspace.retain(_key);
    source
      ..update(_title, const StringValue("Draft"))
      ..markContractUnavailable("Catalog unavailable");

    expect(source.contractUnavailable, isTrue);
    expect(source.readOnly, isTrue);
    expect(source.value(_title).valueOrNull, const StringValue("Draft"));

    resource.load = () async => _ContractSnapshot(
      "one",
      source.document.copyWith(revision: 2, readOnly: false, diagnostics: []),
    );
    expect(await source.retryContractRefresh(), isTrue);
    expect(source.contractUnavailable, isFalse);
    expect(source.readOnly, isFalse);
    expect(source.value(_title).valueOrNull, const StringValue("Draft"));
  });

  test(
    "replacement preserves drafts and uses current validation and commit",
    () async {
      final workspace = LocalWorkSession();
      addTearDown(workspace.dispose);
      var oldSends = 0;
      var newSends = 0;
      var reject = true;
      final source = workspace.editor(
        _target(
          commit: (commit) async {
            oldSends++;
            return MutationSuccess(revision: 2, value: commit.rootValue);
          },
        ),
      );

      workspace.retain(_key);
      source.update(_title, const StringValue("Draft"));
      final replacement = workspace.editor(
        _target(
          revision: 2,
          description: "Remote description",
          validateDraft: (_) => reject
              ? [
                  const TypeDiagnostic(
                    code: TypeDiagnosticCode.invalidValue,
                    message: "Current validation",
                  ),
                ]
              : [],
          commit: (commit) async {
            newSends++;
            expect(commit.expectedRevision, 2);
            return MutationSuccess(revision: 3, value: commit.rootValue);
          },
        ),
      );
      expect(replacement, same(source));
      expect(source.value(_title).valueOrNull, const StringValue("Draft"));
      expect(
        source.value(_description).valueOrNull,
        const StringValue("Remote description"),
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
    final workspace = LocalWorkSession();
    addTearDown(workspace.dispose);
    final response = Completer<TypedMutationResult>();
    final sent = Completer<EditorCommit>();
    var newSends = 0;
    final source = workspace.editor(
      _target(
        commit: (commit) {
          sent.complete(commit);
          return response.future;
        },
      ),
    );

    workspace.retain(_key);
    source.update(_title, const StringValue("First"));
    final pending = source.flush();
    final captured = await sent.future;
    workspace.editor(
      _target(
        commit: (commit) async {
          newSends++;
          return MutationSuccess(revision: 3, value: commit.rootValue);
        },
      ),
    );
    response.complete(MutationSuccess(revision: 2, value: captured.rootValue));

    expect(await pending, isA<MutationSuccess>());
    expect(newSends, 0);
    source.update(_title, const StringValue("Second"));
    expect(await source.flush(), isA<MutationSuccess>());
    expect(newSends, 1);
  });

  test(
    "replacement keeps uncertain replay bound to its original operation",
    () async {
      final workspace = LocalWorkSession();
      addTearDown(workspace.dispose);
      var replays = 0;
      var newSends = 0;
      final source = workspace.editor(
        _target(
          commit: (commit) async {
            return MutationUncertain(
              message: "Lost response",
              cause: TimeoutException("Lost response"),
              stackTrace: StackTrace.current,
              replay: () async {
                replays++;
                return MutationSuccess(revision: 2, value: commit.rootValue);
              },
            );
          },
        ),
      );
      workspace.retain(_key);

      source.update(_title, const StringValue("Submitted"));
      expect(await source.flush(), isA<MutationUncertain>());
      workspace.editor(
        _target(
          commit: (commit) async {
            newSends++;
            return MutationSuccess(revision: 3, value: commit.rootValue);
          },
        ),
      );
      expect(await source.flush(), isA<MutationSuccess>());
      expect(replays, 1);
      expect(newSends, 0);
    },
  );

  test("commit policy cannot change for an existing resource", () {
    final workspace = LocalWorkSession();
    addTearDown(workspace.dispose);
    Future<TypedMutationResult> commit(EditorCommit commit) async =>
        MutationSuccess(revision: 2, value: commit.rootValue);
    workspace.editor(_target(commit: commit));
    expect(
      () => workspace.editor(
        _target(commit: commit, policy: EditorCommitPolicy.autosaveChanges),
      ),
      throwsStateError,
    );
    expect(
      workspace.resources[_key]!.source.commitPolicy,
      EditorCommitPolicy.applyResource,
    );
  });
}

ResourceEditorTarget _contractTarget(
  String contract,
  int revision,
  String description,
) {
  final snapshot = _ContractSnapshot(
    contract,
    EditorDocument(
      rootType: RecordType(
        fields: const {
          "title": TypeField(name: "title", type: StringType()),
          "description": TypeField(name: "description", type: StringType()),
        },
      ),
      typeCatalog: const TypeCatalog([]),
      confirmedValue: _value("Original", description),
      revision: revision,
    ),
  );
  return ResourceEditorTarget(
    targetId: _key.identity,
    label: "Resource",
    resource: FakeEditableResource(
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
}
