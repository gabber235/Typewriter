part of "selection_editor_source_test.dart";

final _sourceProvider = Provider<SelectionEditorSource>((ref) {
  final source = SelectionEditorSource(ref);
  ref.onDispose(source.dispose);
  return source;
});

EditorValue _missingEditorValue() => EditorValue.invalid([
  const TypeDiagnostic(
    code: TypeDiagnosticCode.invalidValue,
    message: "The editor value is missing",
  ),
]);

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
  final EditorValue current;
  final EditorMutationResult mutation;
  final bool loading;
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
  DataPath? updatedPath;
  DataValue? updatedValue;

  @override
  String get name => id.id;

  @override
  List<SelectionCapability> get capabilities => const [];

  @override
  ResolvedTypeRef get rootType => id.rootDefinition.id;

  @override
  TypeCatalog get typeCatalog => id.typeCatalog;

  @override
  Widget? buildInspectorHeader() => null;

  @override
  EditorValue value(DataPath path) => id.current;

  @override
  EditorMutationResult validateUpdate(DataPath path, DataValue value) =>
      id.mutation;

  @override
  EditorMutationResult update(DataPath path, DataValue value) {
    updatedPath = path;
    updatedValue = value;
    return id.mutation;
  }
}

_Identifier _identifier(
  String id,
  EditorValue value, {
  TypeExpression rootType = const StringType(),
  EditorMutationResult mutation = const EditorMutationResult.applied(
    StringValue("updated"),
  ),
}) =>
    _Identifier(id: id, rootType: rootType, current: value, mutation: mutation);

_Identifier _loadingIdentifier(String id) => _Identifier(
  id: id,
  rootType: const StringType(),
  current: const EditorValue.loading(),
  loading: true,
);

_Identifier _invalidIdentifier(String id, String message) => _identifier(
  id,
  EditorValue.invalid([
    TypeDiagnostic(code: TypeDiagnosticCode.invalidValue, message: message),
  ]),
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
