import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../support/test_utils.dart";

void main() {
  testWidgets("resource details omit non UUID submission identities", (
    tester,
  ) async {
    const key = EditorResourceKey(scope: "test", identity: "uncertain");
    final document = EditorDocument(
      rootType: RecordType(
        fields: const {"name": TypeField(name: "name", type: StringType())},
      ),
      typeCatalog: const TypeCatalog([]),
      confirmedValue: RecordValue({"name": StringValue("canonical")}),
      revision: 1,
    );
    final snapshot = FakeEditorSnapshot(
      document,
      validation: acceptTestEditorMutation,
    );
    final workspace = LocalWorkSession();
    addTearDown(workspace.dispose);
    final source = workspace.editor(
      ResourceEditorTarget(
        targetId: key.identity,
        label: "Uncertain configuration",
        resource: _UncertainResource(key, snapshot),
        snapshot: snapshot,
        commitPolicy: EditorCommitPolicy.applyResource,
      ),
    );
    workspace.retain(key);
    source.update(
      DataPath.root.field("name"),
      const StringValue("local draft"),
    );
    expect(await source.flush(), isA<MutationUncertain>());

    await tester.pumpTestApp(
      child: Scaffold(
        appBar: AppBar(
          actions: [LocalWorkSessionActivityView(controller: workspace)],
        ),
      ),
    );
    await tester.tap(find.text("Needs attention"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Outcome unknown. Verify before retrying."));
    await tester.pumpAndSettle();

    expect(find.text("Submission"), findsNothing);
    expect(find.text("Show details"), findsNothing);
    expect(find.text("Hide details"), findsNothing);
  });
}

final class _UncertainResource implements EditableResource {
  _UncertainResource(this.key, this.snapshot);

  @override
  final EditorResourceKey key;
  final EditorSnapshot snapshot;

  @override
  Set<Object> get reservations => {key};

  @override
  Future<EditorSnapshot?> refresh() async => snapshot;

  @override
  MutationIntent prepare(
    EditorSnapshot snapshot,
    EditorCommit changes,
    void Function(TypedMutationResult) accept,
  ) => IndependentMutation(
    PendingCommit<TypedMutationResult>(
      resources: reservations,
      prepare: () => PreparedCommit<TypedMutationResult>(
        id: "not-a-uuid",
        label: "Uncertain configuration",
        resources: reservations,
        send: () async => SubmissionResult<TypedMutationResult>.uncertain(
          message: "The response could not be confirmed",
          cause: StateError("response lost"),
          stackTrace: StackTrace.current,
        ),
      ),
    ),
  );
}
