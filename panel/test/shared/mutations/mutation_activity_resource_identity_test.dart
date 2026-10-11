import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../support/test_utils.dart";

void main() {
  testWidgets("resource details omit non UUID submission identities", (
    tester,
  ) async {
    const key = EditorResourceKey(scope: "test", identity: "uncertain");
    final document = EditorDocument(
      rootType: skir.TypeUse.wrapNamed(
        skir.NamedTypeUse(definition: _recordType, arguments: const []),
      ),
      catalog: _recordCatalog,
      confirmedValue: skir.DataValue.createRecord(
        fields: [
          skir.FieldValue(
            name: "name",
            value: skir.DataValue.wrapStringValue("canonical"),
          ),
        ],
      ),
      revision: 1,
    );
    final snapshot = FakeEditorSnapshot(
      document,
      validation: acceptTestEditorMutation,
    );
    final workspace = ScopedWorkSession();
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
      editorRootPath.field("name"),
      skir.DataValue.wrapStringValue("local draft"),
    );
    expect(await source.flush(), isA<MutationUncertain>());

    await tester.pumpTestApp(
      child: Scaffold(
        appBar: AppBar(
          actions: [ScopedWorkSessionActivityView(controller: workspace)],
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

final _recordType = skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "test", name: "Resource"),
  revision: 1,
);
final _recordField = skir.EffectiveFieldTemplate(
  key: "name",
  owner: skir.FieldOwner(definition: _recordType, name: "name"),
  type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
  rules: const [],
);
final _recordCatalog = CheckedEditorCatalog(
  skir.EditorCatalogWireSnapshot(
    generation: skir.CatalogGeneration(value: "test"),
    types: [
      skir.PublishedType(
        display: null,
        definition: skir.TypeDefinition(
          id: _recordType,
          parameters: const [],
          representation: skir.RepresentationTemplate.createRecord(
            fields: [
              skir.FieldDeclaration(
                owner: _recordField.owner,
                type: _recordField.type,
                overrides: const [],
                hasConstructorDefault: false,
              ),
            ],
            abstract_: false,
          ),
          parents: const [],
        ),
        status: skir.DeclarationStatus.ready,
        effectiveFields: [_recordField],
        ancestorTemplates: const [],
      ),
    ],
    relations: const [],
    resourceDefinitions: const [],
    presentations: const [],
    presentationMaterials: const [],
    configuration: const [],
    diagnostics: const [],
    initialization: const [],
    endpointBindings: const [],
    capabilities: const [],
    recommendations: const [],
    roleFallbacks: const [],
  ),
);

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
