import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

part "test_selectable.g.dart";

@Riverpod(keepAlive: true)
class TestSelectableData extends _$TestSelectableData {
  @override
  Map<String, skir.DataValue> build() => {};

  void set(String id, skir.DataValue data) {
    state = {...state, id: data};
  }

  @override
  bool updateShouldNotify(
    Map<String, skir.DataValue> previous,
    Map<String, skir.DataValue> next,
  ) => !mapEquals(previous, next);
}

@riverpod
skir.DataValue? testData(Ref ref, String id) =>
    ref.watch(testSelectableDataProvider)[id];

class TestSelectableIdentifier extends SelectableIdentifier {
  TestSelectableIdentifier({
    required this.id,
    this.color = Colors.redAccent,
    this.onDelete,
  });

  @override
  final String id;
  final Color color;
  final VoidCallback? onDelete;

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestSelectableIdentifier &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  AsyncValue<Selectable> create(Ref ref) {
    final data =
        ref.watch(testDataProvider(id)) ??
        skir.DataValue.createRecord(
          fields: [
            skir.FieldValue(
              name: "name",
              value: skir.DataValue.wrapStringValue(id.formatted),
            ),
          ],
        );
    final document = EditorDocument(
      rootType: skir.TypeUse.wrapNamed(_testSelectableUse),
      catalog: _testSelectableCatalog,
      confirmedValue: data,
      revision: 1,
    );
    final snapshot = FakeEditorSnapshot(
      document,
      validation: _validateTestValue,
    );
    final commands = ref.read(testSelectableDataProvider.notifier);
    final resource = FakeEditableResource(
      key: EditorResourceKey(scope: null, identity: resourceId),
      current: snapshot,
      commit: (commit) async {
        final next = commit.rootValue;
        if (next.authoredRecord == null) {
          return TypedMutationResult.invalid([
            EditorDiagnostic(
              code: EditorDiagnosticCode.invalidValue,
              message: "The selectable root must remain a record",
              path: editorRootPath,
            ),
          ]);
        }
        commands.set(id, next);
        return TypedMutationResult.success(
          revision: commit.expectedRevision + 1,
          value: next,
        );
      },
    );
    return AsyncValue.data(
      TestSelectable(
        resource: resource,
        id: this,
        data: data,
        color: color,
        onDelete: onDelete,
      ),
    );
  }

  @override
  String toString() => "TestSelectableIdentifier(id: $id)";
}

class TestSelectable extends InspectableSelectable<TestSelectableIdentifier>
    implements EditorTarget {
  TestSelectable({
    required this.resource,
    required this.id,
    required this.data,
    required this.color,
    required this.onDelete,
  });

  @override
  final EditableResource resource;

  @override
  final TestSelectableIdentifier id;

  final skir.DataValue data;
  final Color color;
  final VoidCallback? onDelete;

  @override
  late final EditorDocument document = EditorDocument(
    rootType: skir.TypeUse.wrapNamed(_testSelectableUse),
    catalog: _testSelectableCatalog,
    confirmedValue: data,
    revision: 1,
  );

  @override
  List<SelectionCapability> get capabilities => [
    if (onDelete != null) DeleteSelectionCapability(onDelete: onDelete!),
  ];

  @override
  SelectableIdentifier get targetId => id;

  @override
  String get label => name;

  @override
  EditorCommitPolicy get commitPolicy => EditorCommitPolicy.autosaveChanges;

  @override
  int get hashCode => Object.hash(id, data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestSelectable &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          data == other.data;

  @override
  String get name =>
      (data.authoredField("name")?.authoredString ?? id.id).formatted;

  @override
  InspectionContent buildInspection(EditorOwnerScope owners) {
    final owner = owners.editor(this);
    final title = skir.ExpressionBindingId(value: "testSelectable.name");
    return InspectionContent(
      host: EditorSourcePresentationHost(
        catalog: _testSelectableCatalog,
        root: () => title.readExpression().resourceHeading(
          id: "testSelectable",
          color: color.portableExpression,
          identifier: id.id.portableExpression,
        ),
        bindings: [
          EditorSourcePresentationBinding(
            id: title,
            use: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
            owner: owner,
            read: (_) => skir.DataValue.wrapStringValue(
              owner.value(_fieldPath("name")).valueOrNull?.authoredString ??
                  name,
            ),
          ),
        ],
        budget: skir.EvaluationBudget(maxSteps: 256, maxCollectionItems: 16),
      ),
    );
  }

  @override
  EditorSnapshot get snapshot =>
      FakeEditorSnapshot(document, validation: validate);

  @override
  List<EditorDiagnostic> validateDraft(skir.DataValue value) =>
      snapshot.validateDraft(value);

  @override
  EditorValue value(skir.ValuePath path) => data.readEditorValue(path);

  @override
  EditorMutationResult validate(skir.ValuePath path, skir.DataValue value) =>
      _validateTestValue(path, value);

  @override
  String toString() => "TestSelectable(id: $id, name: $name)";
}

EditorMutationResult _validateTestValue(
  skir.ValuePath path,
  skir.DataValue value,
) {
  if (path.segments.isEmpty ||
      path == _fieldPath("name") && value.authoredString != null) {
    return EditorMutationResult.applied(value);
  }
  return EditorMutationResult.invalid([
    EditorDiagnostic(
      code: EditorDiagnosticCode.invalidValue,
      message: "The test selectable value is invalid",
      path: path,
    ),
  ]);
}

skir.ValuePath _fieldPath(String name) =>
    skir.ValuePath(segments: [skir.PathSegment.createField(name: name)]);

final _testSelectableDefinition = skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "testkit", name: "selectable"),
  revision: 1,
);
final _testSelectableUse = skir.NamedTypeUse(
  definition: _testSelectableDefinition,
  arguments: const [],
);
final _testSelectableCatalog = CheckedEditorCatalog(
  skir.EditorCatalogWireSnapshot(
    generation: skir.CatalogGeneration(value: "testkit:selectable"),
    types: [
      skir.PublishedType(
        display: null,
        definition: skir.TypeDefinition(
          id: _testSelectableDefinition,
          parameters: const [],
          representation: skir.RepresentationTemplate.createRecord(
            fields: [
              skir.FieldDeclaration(
                owner: skir.FieldOwner(
                  definition: _testSelectableDefinition,
                  name: "name",
                ),
                type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
                overrides: const [],
                hasConstructorDefault: false,
              ),
            ],
            abstract_: false,
          ),
          parents: const [],
        ),
        status: skir.DeclarationStatus.ready,
        effectiveFields: [
          skir.EffectiveFieldTemplate(
            key: "name",
            owner: skir.FieldOwner(
              definition: _testSelectableDefinition,
              name: "name",
            ),
            type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
            rules: const [],
          ),
        ],
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
