import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _key = EditorResourceKey(scope: "org1", identity: "resource");
final _title = editorRootPath.field("title");
final _description = editorRootPath.field("description");

/// The record's two text fields, title and description.
final _textFields = {
  "title": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
  "description": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
};

/// The record as it was saved.
final _saved = recordEditorDocument(
  texts({"title": "Original", "description": "Original description"}),
  _textFields,
  1,
);

/// The record as the first contract read it.
final _remoteOne = recordEditorDocument(
  texts({"title": "Original", "description": "Remote one"}),
  _textFields,
  1,
);

/// The record as the second contract read it, one revision later.
final _remoteTwo = recordEditorDocument(
  texts({"title": "Original", "description": "Remote two"}),
  _textFields,
  2,
);

void main() {
  test(
    "incompatible replacement stays pending across a host rebuild",
    () async {
    final workspace = testWorkSession();
    final source = resourceTarget(
      _key,
      contract: "one",
      document: _remoteOne,
    ).hold(workspace)..update(_title, skir.DataValue.wrapStringValue("Draft"));

    final rebuilt = resourceTarget(
      _key,
      contract: "two",
      document: _remoteTwo,
    ).acquire(workspace);

    expect(rebuilt.workspace, same(source.workspace));
    await eventually(
      () => expect(source.contractReconciliationPending, isTrue),
    );
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
  },
  );

  test("discard accepts an incompatible replacement explicitly", () async {
    final workspace = testWorkSession();
    final source = resourceTarget(
      _key,
      contract: "one",
      document: _remoteOne,
    ).hold(workspace)..update(_title, skir.DataValue.wrapStringValue("Draft"));
    resourceTarget(
      _key,
      contract: "two",
      document: _remoteTwo,
    ).acquire(workspace);
    await eventually(
      () => expect(source.contractReconciliationPending, isTrue),
    );

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
    final workspace = testWorkSession();
    final target = resourceTarget(_key, contract: "one", document: _remoteOne);
    final resource = target.persistence as ScriptedValuePersistence;
    final source = target.acquire(workspace);
    holdValueLease(workspace, _key);
    source
      ..update(_title, skir.DataValue.wrapStringValue("Draft"))
      ..markContractUnavailable("Catalog unavailable");

    await eventually(() => expect(source.contractUnavailable, isTrue));
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
      final workspace = testWorkSession();
      var oldSends = 0;
      var newSends = 0;
      var reject = true;
      final source =
          resourceTarget(
              _key,
              document: _saved,
              commit: (commit) async {
                oldSends++;
                return MutationSuccess(revision: 2, value: commit.rootValue);
              },
            ).hold(workspace)
            ..update(_title, skir.DataValue.wrapStringValue("Draft"));
      final replacement = resourceTarget(
        _key,
        document: recordEditorDocument(
          texts({"title": "Original", "description": "Remote description"}),
          _textFields,
          2,
        ),
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
      await eventually(
        () => expect(
          source.value(_description).valueOrNull,
          skir.DataValue.wrapStringValue("Remote description"),
        ),
      );
      expect(
        source.value(_title).valueOrNull,
        skir.DataValue.wrapStringValue("Draft"),
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
    final workspace = testWorkSession();
    final response = Completer<TypedMutationResult>();
    final sent = Completer<EditorCommit>();
    var newSends = 0;
    final source = resourceTarget(
      _key,
      document: _saved,
      commit: (commit) {
        sent.complete(commit);
        return response.future;
      },
    ).hold(workspace)..update(_title, skir.DataValue.wrapStringValue("First"));
    final pending = source.flush();
    final captured = await sent.future;
    resourceTarget(
      _key,
      document: _saved,
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
    final workspace = testWorkSession();
    Future<TypedMutationResult> commit(EditorCommit commit) async =>
        MutationSuccess(revision: 2, value: commit.rootValue);
    resourceTarget(_key, document: _saved, commit: commit).acquire(workspace);
    expect(
      () => resourceTarget(
        _key,
        document: _saved,
        commitPolicy: EditorCommitPolicy.autosaveChanges,
        commit: commit,
      ).acquire(workspace),
      throwsStateError,
    );
    expect(
      resourceTarget(
        _key,
        document: _saved,
        commit: commit,
      ).acquire(workspace).commitPolicy,
      EditorCommitPolicy.applyResource,
    );
  });
}
