import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

final _title = DataPath.root.field("title");
RecordValue _value(String title) => RecordValue({"title": StringValue(title)});
EditorDocument _document(String title, int revision) => EditorDocument(
  rootType: RecordType(
    fields: const {"title": TypeField(name: "title", type: StringType())},
  ),
  typeCatalog: const TypeCatalog([]),
  confirmedValue: _value(title),
  revision: revision,
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
      source.update(_title, const StringValue("Submitted"));
      expect(await source.flush(), isA<MutationUncertain>());
      source.update(_title, const StringValue("New draft"));

      expect(await source.flush(), isA<MutationUncertain>());
      source.discardDraft();
      expect(source.value(_title).valueOrNull, const StringValue("New draft"));
      expect(source.saveState(DataPath.root).canRetry, isFalse);
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
      source.update(_title, const StringValue("A"));
      await source.flush();

      source.update(_title, const StringValue("B"));
      await source.flush();
      expect(sends, 2);
      expect(captured, hasLength(1));
      expect(source.document.confirmedValue, _value("A"));
      expect(source.value(_title).valueOrNull, const StringValue("B"));

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
                const TypeDiagnostic(
                  code: TypeDiagnosticCode.invalidValue,
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
      source.update(_title, const StringValue(""));
      await interaction.commit();

      expect(sends, 0);
      expect(await source.flush(), isA<MutationInvalid>());
      expect(sends, 0);
      source.update(_title, const StringValue("Complete"));
      expect(await source.flush(), isA<MutationSuccess>());
      expect(sends, 1);
    },
  );

  test(
    "session workspace retains drafts and isolates resource scope",
    () async {
      final workspace = LocalWorkSession();
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
        ..update(_title, const StringValue("Retained"));
      first.dispose();

      final other = EditorOwnerRegistry(workspace: workspace);
      final returned = EditorOwnerRegistry(workspace: workspace);
      addTearDown(other.dispose);
      addTearDown(returned.dispose);
      expect(
        other.editor(target("org2")).value(_title).valueOrNull,
        const StringValue("Original"),
      );
      expect(identical(returned.editor(target("org1")), source), isTrue);

      expect(source.value(_title).valueOrNull, const StringValue("Retained"));
      await source.flush();
      expect(source.hasWork, isFalse);
    },
  );
}
