import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../support/editor_fixture.dart";

final _title = editorRootPath.field("title");
skir.DataValue _value(String title) =>
    recordEditorValue({"title": skir.DataValue.wrapStringValue(title)});

final _fieldTypes = {
  "title": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
};
EditorDocument _document(String title, int revision) => recordEditorDocument(
  {"title": skir.DataValue.wrapStringValue(title)},
  _fieldTypes,
  revision,
);

void main() {
  test(
    "uncertain delivery blocks fresh requests and cannot discard evidence",
    () async {
      var sends = 0;
      final source = TransactionalEditorSource(
        document: _document("Original", 1),
        validation: acceptTestEditorMutation,
        debounce: const Duration(days: 1),
        commit: (_) async {
          sends++;
          throw TimeoutException("Lost response");
        },
      );
      addTearDown(source.dispose);
      source.update(_title, skir.DataValue.wrapStringValue("Submitted"));
      expect(await source.flush(), isA<MutationUncertain>());
      source.update(_title, skir.DataValue.wrapStringValue("New draft"));

      expect(await source.flush(), isA<MutationUncertain>());
      source.discardDraft();
      expect(
        source.value(_title).valueOrNull,
        skir.DataValue.wrapStringValue("New draft"),
      );
      expect(source.saveState(editorRootPath).canRetry, isFalse);
      expect(sends, 1);
    },
  );

  test(
    "replay acknowledges captured edits while preserving newer edits",
    () async {
      var sends = 0;
      final captured = <EditorCommit>[];
      final source = TransactionalEditorSource(
        document: _document("Original", 1),
        validation: acceptTestEditorMutation,
        debounce: const Duration(days: 1),
        commit: (commit) async {
          captured.add(commit);
          sends++;
          return MutationUncertain(
            message: "Lost response",
            cause: TimeoutException("Lost response"),
            stackTrace: StackTrace.current,
            replay: () async {
              sends++;
              return MutationSuccess(revision: 2, value: commit.rootValue);
            },
          );
        },
      );
      addTearDown(source.dispose);
      source.update(_title, skir.DataValue.wrapStringValue("A"));
      await source.flush();

      source.update(_title, skir.DataValue.wrapStringValue("B"));
      await source.flush();
      expect(sends, 2);
      expect(captured, hasLength(1));
      expect(source.document.confirmedValue, _value("A"));
      expect(
        source.value(_title).valueOrNull,
        skir.DataValue.wrapStringValue("B"),
      );

      expect(source.hasWork, isTrue);
    },
  );

  test(
    "Apply ignores interaction commits and validates the whole draft",
    () async {
      var sends = 0;
      final source = TransactionalEditorSource(
        document: _document("Original", 1),
        validation: acceptTestEditorMutation,
        commitPolicy: EditorCommitPolicy.applyResource,
        validateDraft: (value) => value == _value("")
            ? [
                const EditorDiagnostic(
                  code: EditorDiagnosticCode.invalidValue,
                  message: "Choose a title",
                ),
              ]
            : [],
        commit: (commit) async {
          sends++;
          return MutationSuccess(revision: 2, value: commit.rootValue);
        },
      );
      addTearDown(source.dispose);
      final interaction = source.beginInteraction(_title);
      source.update(_title, skir.DataValue.wrapStringValue(""));
      await interaction.commit();

      expect(sends, 0);
      expect(await source.flush(), isA<MutationInvalid>());
      expect(sends, 0);
      source.update(_title, skir.DataValue.wrapStringValue("Complete"));
      expect(await source.flush(), isA<MutationSuccess>());
      expect(sends, 1);
    },
  );

  test(
    "session workspace retains drafts and isolates resource scope",
    () async {
      final workspace = ScopedWorkSession();
      addTearDown(workspace.dispose);
      ResourceEditorTarget target(String scope) => fakeEditorTarget(
        scope: scope,
        targetId: "resource",
        label: "Resource",
        document: _document("Original", 1),
        commitPolicy: EditorCommitPolicy.applyResource,
        validation: acceptTestEditorMutation,
        commit: (commit) async =>
            MutationSuccess(revision: 2, value: commit.rootValue),
      );
      final first = EditorOwnerRegistry(workspace: workspace);
      final source = (first.editor(target("org1")))
        ..update(_title, skir.DataValue.wrapStringValue("Retained"));
      first.dispose();

      final other = EditorOwnerRegistry(workspace: workspace);
      final returned = EditorOwnerRegistry(workspace: workspace);
      addTearDown(other.dispose);
      addTearDown(returned.dispose);
      expect(
        other.editor(target("org2")).value(_title).valueOrNull,
        skir.DataValue.wrapStringValue("Original"),
      );
      expect(identical(returned.editor(target("org1")), source), isTrue);

      expect(
        source.value(_title).valueOrNull,
        skir.DataValue.wrapStringValue("Retained"),
      );
      await source.flush();
      expect(source.hasWork, isFalse);
    },
  );
}
