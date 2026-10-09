import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

part "test_selectable.g.dart";

@Riverpod(keepAlive: true)
class TestSelectableData extends _$TestSelectableData {
  @override
  Map<String, RecordValue> build() {
    return {};
  }

  void set(String id, RecordValue data) {
    state = {...state, id: data};
  }

  @override
  bool updateShouldNotify(
    Map<String, RecordValue> previous,
    Map<String, RecordValue> next,
  ) {
    return !mapEquals(previous, next);
  }
}

@riverpod
RecordValue? testData(Ref ref, String id) {
  final data = ref.watch(testSelectableDataProvider)[id];
  return data;
}

class TestSelectableIdentifier extends SelectableIdentifier {
  TestSelectableIdentifier({
    required this.id,
    RecordType? rootType,
    this.color = Colors.redAccent,
    this.onDelete,
  }) : representation =
           rootType ??
           RecordType(
             fields: const {
               "name": TypeField(name: "name", type: StringType()),
             },
           );

  @override
  final String id;
  final RecordType representation;
  final Color color;
  final VoidCallback? onDelete;

  late final TypeDefinition rootDefinition = TypeDefinition(
    id: ResolvedTypeRef(
      id: QualifiedTypeId(namespace: "testkit", name: id),
      revision: 1,
    ),
    kind: NominalTypeKind.concrete,
    representation: representation,
  );

  late final TypeCatalog typeCatalog = TypeCatalog([rootDefinition]);

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
        RecordValue(const {})
            .withField("name", id.formatted.asValue)
            .withField("color", color.asValue);

    final document = EditorDocument(
      rootType: NamedType(rootDefinition.id),
      typeCatalog: typeCatalog,
      confirmedValue: data,
      revision: 1,
    );
    final snapshot = FakeEditorSnapshot(
      document,
      validation: (path, value) =>
          _validateTestRecord(representation, path, value),
    );
    final commands = ref.read(testSelectableDataProvider.notifier);
    final resource = FakeEditableResource(
      key: EditorResourceKey(scope: null, identity: resourceId),
      current: snapshot,
      commit: (commit) async {
        final next = commit.rootValue;
        if (next is! RecordValue) {
          return TypedMutationResult.invalid([
            const TypeDiagnostic(
              code: TypeDiagnosticCode.invalidValue,
              message: "The selectable root must remain a record",
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
        rootDefinition: rootDefinition,
        typeCatalog: typeCatalog,
        data: data,
        color: color,
        onDelete: onDelete,
      ),
    );
  }

  @override
  String toString() {
    return "TestSelectableIdentifier(id: $id)";
  }
}

class TestSelectable extends InspectableSelectable<TestSelectableIdentifier>
    implements EditorTarget {
  TestSelectable({
    required this.resource,
    required this.id,
    required this.rootDefinition,
    required this.typeCatalog,
    required this.data,
    required this.color,
    required this.onDelete,
  });

  @override
  final EditableResource resource;

  @override
  final TestSelectableIdentifier id;

  final TypeDefinition rootDefinition;

  final TypeCatalog typeCatalog;

  final RecordValue data;

  final Color color;

  final VoidCallback? onDelete;

  @override
  late final EditorDocument document = EditorDocument(
    rootType: NamedType(rootDefinition.id),
    typeCatalog: typeCatalog,
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

  ResolvedTypeRef get rootType => rootDefinition.id;

  @override
  int get hashCode => Object.hash(id, rootType, data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestSelectable &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          rootType == other.rootType &&
          data == other.data;

  @override
  String get name {
    final value = data.fields["name"];
    final name = value?.asStringOrNull;
    return (name?.nullIfEmpty ?? id.id).formatted;
  }

  @override
  InspectionContent buildInspection(EditorOwnerScope owners) {
    final owner = owners.editor(this);
    final title = skir.ExpressionBindingId(value: "testSelectable.name");
    return InspectionContent(
      host: EditorSourcePresentationHost(
        catalog: skir.EditorCatalogWireSnapshot.defaultInstance
            .asTrustedLocalCatalog(),
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
              owner
                      .value(DataPath.root.field("name"))
                      .valueOrNull
                      ?.asStringOrNull ??
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
  List<TypeDiagnostic> validateDraft(DataValue value) =>
      snapshot.validateDraft(value);

  @override
  EditorValue value(DataPath path) => data.readEditorValue(path);

  @override
  EditorMutationResult validate(DataPath path, DataValue value) =>
      _validateTestRecord(rootDefinition.representation, path, value);

  @override
  String toString() {
    return "TestSelectable(id: $id, name: $name)";
  }
}

EditorMutationResult _validateTestRecord(
  TypeExpression representation,
  DataPath path,
  DataValue value,
) {
  final expected = switch ((representation, path.segments)) {
    (final type, []) => type,
    (RecordType(:final fields), [FieldPathSegment(:final name)]) =>
      fields[name]?.type,
    _ => null,
  };
  if (expected == null) {
    return EditorMutationResult.invalid([
      TypeDiagnostic(
        code: TypeDiagnosticCode.invalidPath,
        message: "The test selectable path is unavailable",
        path: path,
      ),
    ]);
  }
  final diagnostics = value.validateAgainst(expected, path: path);
  return diagnostics.isEmpty
      ? EditorMutationResult.applied(value)
      : EditorMutationResult.invalid(diagnostics);
}
