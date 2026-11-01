import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

final _title = editorRootPath.field("title");

/// A record of one text field title holding "Original", at revision 1.
final original = recordEditorDocument(
  {"title": skir.DataValue.wrapStringValue("Original")},
  {"title": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text)},
  1,
);

void main() {
  test(
    "uncertain delivery blocks fresh requests and cannot discard evidence",
    () async {
      var sends = 0;
      late final ScriptedValuePersistence saved;
      saved = ScriptedValuePersistence(
        key: const EditorResourceKey(scope: null, identity: "title"),
        current: CallbackEditorSnapshot(
          original,
          acceptTestEditorMutation,
          null,
        ),
        commit: (_) async {
          sends++;
          // The saved values stay unread, so the outcome stays unknown.
          saved.load = () => Completer<EditorSnapshot?>().future;
          throw TimeoutException("Lost response");
        },
      );
      final source = fakeValueEditing(
        document: original,
        validation: acceptTestEditorMutation,
        debounce: const Duration(days: 1),
        persistence: saved,
      );
      addTearDown(source.dispose);
      source.update(_title, skir.DataValue.wrapStringValue("Submitted"));
      expect(await source.flush(), isA<MutationUncertain>());
      source.update(_title, skir.DataValue.wrapStringValue("New draft"));

      expect(await source.flush(), isA<MutationUncertain>());
      source.discardDraft();
      expect(
        source.value(_title).valueOrNull,
        skir.DataValue.wrapStringValue("Submitted"),
      );
      expect(source.saveState(editorRootPath).canRetry, isFalse);
      expect(sends, 1);
    },
  );

  test(
    "Apply ignores interaction commits and validates the whole draft",
    () async {
      var sends = 0;
      final source = fakeValueEditing(
        document: original,
        validation: acceptTestEditorMutation,
        commitPolicy: EditorCommitPolicy.applyResource,
        validateDraft: (value) => value == titleValue("")
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
      final workspace = testWorkSession();
      ValueEditingRegistration target(String scope) => fakeEditorTarget(
        scope: scope,
        targetId: "resource",
        label: "Resource",
        document: original,
        commitPolicy: EditorCommitPolicy.applyResource,
        validation: acceptTestEditorMutation,
        commit: (commit) async =>
            MutationSuccess(revision: 2, value: commit.rootValue),
      );
      final first = InspectionBindings(workspace: workspace);
      final source = (first.editor(target("org1")))
        ..update(_title, skir.DataValue.wrapStringValue("Retained"));
      first.dispose();

      final other = InspectionBindings(workspace: workspace);
      final returned = InspectionBindings(workspace: workspace);
      addTearDown(other.dispose);
      addTearDown(returned.dispose);
      expect(
        other.editor(target("org2")).value(_title).valueOrNull,
        skir.DataValue.wrapStringValue("Original"),
      );
      expect(
        returned.editor(target("org1")).value(_title).valueOrNull,
        skir.DataValue.wrapStringValue("Retained"),
      );
      await source.flush();
      expect(source.hasWork, isFalse);
    },
  );
}
