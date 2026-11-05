import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

final _page = skir.ResourceId(value: "page:contract");

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  editingWorkspaceContract<ValueEditDocument, ValueEdit>(
    "Value model",
    model: const ValueEditModel(),
    initial: () => ValueEditDocument.fromSnapshot(
      FakeEditorSnapshot(
        EditorDocument(
          rootType: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
          catalog: skir.EditorCatalog.defaultInstance.asTrustedLocalCatalog(),
          confirmedValue: skir.DataValue.wrapStringValue("Original"),
          revision: 1,
        ),
        validation: acceptTestEditorMutation,
      ),
      identity: "contract",
    ),
    change: (document, value) => ValueEdit(
      baseline: document,
      proposed: skir.DataValue.wrapStringValue(value),
      paths: {editorRootPath},
      mutations: [
        EditorSetValue(editorRootPath, skir.DataValue.wrapStringValue(value)),
      ],
    ),
    read: (document) => document.value.authoredString!,
    accepted: (document) => document.copyWith(
      metadata: ResultEditorSnapshot(
        document.metadata,
        document.metadata.document.copyWith(
          revision: document.revision + 1,
          confirmedValue: document.value,
        ),
      ),
    ),
    inspectActiveSave: (owner, group) {
      final value = ValueEditing.fromWorkspace(owner, group);
      final status = value.saveState(editorRootPath);
      expect(status.phase, EditorSavePhase.saving);
      expect(status.diagnostics, isEmpty);
    },
  );
  editingWorkspaceContract<AuthoringDocument, RealmPreparedEdit>(
    "Realm model",
    model: const RealmEditModel(),
    initial: () => realmDocument(
      pages: [
        Page(
          pageId: _page,
          bookId: null,
          name: "Original",
          chapter: "Introduction",
          priority: 0,
        ),
      ],
    ),
    change: (document, value) {
      final edit = AuthoringEdit.fromDocument(document)
        ..set(
          skir.ValueLocation(
            resource: _page,
            path: editorRootPath.field("name"),
          ),
          skir.DataValue.wrapStringValue(value),
        );
      return RealmPreparedEdit(request: edit.prepare());
    },
    read: (document) =>
        document.resource(_page)!.authoredField("name")!.authoredString!,
    accepted: (document) => document.copyWith(revision: document.revision + 1),
  );
}
