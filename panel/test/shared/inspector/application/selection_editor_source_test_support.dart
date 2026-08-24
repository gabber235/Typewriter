part of "selection_editor_source_test.dart";

final _sourceProvider = Provider<SelectionEditorSource>((ref) {
  final source = SelectionEditorSource(
    ref,
    realmRuntime: ref.watch(editorRealmRuntimeProvider),
  );
  ref.onDispose(source.dispose);
  return source;
}, dependencies: [editorRealmRuntimeProvider]);

class _Identifier extends SelectableIdentifier {
  _Identifier({
    required this.id,
    required TypeExpression rootType,
    required this.current,
    this.mutation = const EditorMutationResult.applied(StringValue("updated")),
    this.loading = false,
  }) : representation = rootType;

  @override
  final String id;
  final TypeExpression representation;
  DataValue current;
  final EditorMutationResult mutation;
  final bool loading;
  int revision = 1;
  bool readOnly = false;
  bool deleted = false;
  _Inspectable? latest;

  late final TypeDefinition rootDefinition = TypeDefinition(
    id: ResolvedTypeRef(
      id: QualifiedTypeId(namespace: "selection_source_test", name: id),
      revision: 1,
    ),
    kind: NominalTypeKind.concrete,
    representation: representation,
  );

  late final TypeCatalog typeCatalog = TypeCatalog([rootDefinition]);

  @override
  AsyncValue<Selectable<_Identifier>> create(Ref ref) {
    if (deleted) {
      return AsyncValue.error(
        SelectableNotFoundException(this),
        StackTrace.current,
      );
    }
    if (loading) return const AsyncValue.loading();
    latest = _Inspectable(this);
    return AsyncValue.data(latest!);
  }

  @override
  bool operator ==(Object other) => other is _Identifier && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class _Inspectable extends InspectableSelectable<_Identifier> {
  _Inspectable(this.id);

  @override
  final _Identifier id;
  DataPath? validatedPath;
  DataValue? validatedValue;
  EditorCommit? latestCommit;

  @override
  String get name => id.id;

  @override
  List<SelectionCapability> get capabilities => const [];

  @override
  EditorDocument get document => EditorDocument(
    rootType: NamedType(id.rootDefinition.id),
    typeCatalog: id.typeCatalog,
    confirmedValue: id.current,
    revision: id.revision,
    readOnly: id.readOnly,
  );

  @override
  Widget? buildInspectorHeader() => null;

  @override
  EditorMutationResult validate(DataPath path, DataValue value) {
    validatedPath = path;
    validatedValue = value;
    return id.mutation;
  }

  @override
  Future<TypedMutationResult> commit(EditorCommit commit) async {
    latestCommit = commit;
    return TypedMutationResult.success(
      revision: commit.expectedRevision + 1,
      value: commit.rootValue,
    );
  }
}

_Identifier _identifier(
  String id,
  DataValue value, {
  TypeExpression rootType = const StringType(),
  EditorMutationResult mutation = const EditorMutationResult.applied(
    StringValue("updated"),
  ),
}) =>
    _Identifier(id: id, rootType: rootType, current: value, mutation: mutation);

_Identifier _loadingIdentifier(String id) => _Identifier(
  id: id,
  rootType: const StringType(),
  current: const StringValue("loading"),
  loading: true,
);

EditorMutationResult _invalidMutation(String message) =>
    EditorMutationResult.invalid([
      TypeDiagnostic(code: TypeDiagnosticCode.invalidValue, message: message),
    ]);

RecordType _recordType(List<String> names) => RecordType(
  fields: {
    for (final name in names)
      name: TypeField(name: name, type: const StringType()),
  },
);

RecordValue _recordValue(List<String> names) =>
    RecordValue({for (final name in names) name: const StringValue("value")});
