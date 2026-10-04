part of "selection_editor_source_test.dart";

final _sourceProvider = inspectionSessionProvider;

EditOwner _owner(InspectionSession session) =>
    (session.hosts.single as _OwnerInspectionHost).owner;

EditorSource _resource(InspectionSession session) =>
    _owner(session) as EditorSource;

class _Identifier extends SelectableIdentifier {
  _Identifier({
    required this.id,
    required TypeExpression rootType,
    required this.current,
    this.mutation = const EditorMutationResult.applied(StringValue("updated")),
    this.loading = false,
    this.surfaceSpecs = const [_TestSurfaceSpec("value")],
  }) : representation = rootType;

  @override
  final String id;
  final TypeExpression representation;
  DataValue current;
  final EditorMutationResult mutation;
  final List<_TestSurfaceSpec> surfaceSpecs;
  bool loading;
  Object? failure;
  int revision = 1;
  bool readOnly = false;
  bool deleted = false;
  int disposedHosts = 0;
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
    if (failure case final error?) {
      return AsyncError(error, StackTrace.current);
    }
    if (deleted) {
      return AsyncError(SelectableNotFoundException(this), StackTrace.current);
    }
    if (loading) return const AsyncLoading();
    latest = _Inspectable(this);
    return AsyncData(latest!);
  }

  @override
  bool operator ==(Object other) => other is _Identifier && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class _Inspectable extends InspectableSelectable<_Identifier>
    implements EditorTarget {
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
  SelectableIdentifier get targetId => id;

  @override
  String get label => name;

  @override
  EditorCommitPolicy get commitPolicy => EditorCommitPolicy.autosaveChanges;

  @override
  EditorDocument get document => EditorDocument(
    rootType: NamedType(id.rootDefinition.id),
    typeCatalog: id.typeCatalog,
    confirmedValue: id.current,
    revision: id.revision,
    readOnly: id.readOnly,
  );

  @override
  List<TypeDiagnostic> validateDraft(DataValue value) =>
      snapshot.validateDraft(value);

  @override
  EditorValue value(DataPath path) =>
      document.confirmedValue.readEditorValue(path);

  @override
  List<PortableMultiInspectionSurface> get portableMultiInspectionSurfaces => [
    for (final spec in id.surfaceSpecs)
      _TestPortableSurface(this, id.representation, spec),
  ];

  @override
  InspectionContent buildInspection(EditorOwnerScope owners) =>
      InspectionContent(
        host: _OwnerInspectionHost(
          owners.editor(this),
          onDispose: () => id.disposedHosts++,
        ),
      );

  @override
  EditorMutationResult validate(DataPath path, DataValue value) {
    validatedPath = path;
    validatedValue = value;
    return id.mutation;
  }

  @override
  EditorSnapshot get snapshot =>
      FakeEditorSnapshot(document, validation: validate);

  @override
  late final EditableResource resource = FakeEditableResource(
    key: EditorResourceKey(scope: null, identity: id.resourceId),
    current: snapshot,
    commit: commit,
    load: () async {
      if (id.loading || id.failure != null) throw StateError("Unavailable");
      return id.deleted ? null : snapshot;
    },
  );

  Future<TypedMutationResult> commit(EditorCommit commit) async {
    latestCommit = commit;
    return TypedMutationResult.success(
      revision: commit.expectedRevision + 1,
      value: commit.rootValue,
    );
  }
}

final class _TestPortableSurface implements PortableMultiInspectionSurface {
  const _TestPortableSurface(this.target, this.rootType, this.spec);

  final _TestSurfaceSpec spec;

  @override
  Object get id => spec.id;

  @override
  final _Inspectable target;

  @override
  final TypeExpression rootType;

  @override
  TypeCatalog get typeCatalog => target.document.typeCatalog;

  @override
  bool isCompatibleWith(PortableMultiInspectionSurface other) =>
      other is _TestPortableSurface && other.spec.id == spec.id;

  @override
  PortablePresentationHost buildHost(
    List<PortableMultiInspectionSurface> members,
    EditOwner combinedOwner,
    Future<void> Function() commit,
  ) {
    if (spec.failBuild) throw StateError("Surface build failed");
    return _OwnerInspectionHost(
      combinedOwner,
      onDispose: () => target.id.disposedHosts++,
    );
  }
}

final class _TestSurfaceSpec {
  const _TestSurfaceSpec(this.id, {this.failBuild = false});

  final String id;
  final bool failBuild;
}

final class _OwnerInspectionHost extends ChangeNotifier
    implements PortablePresentationHost {
  _OwnerInspectionHost(this.owner, {this.onDispose})
    : _document = PortablePresentationDocument(
        catalog: CheckedEditorCatalog(
          portable_catalog.EditorCatalogWireSnapshot.defaultInstance,
        ),
        root: portable_presentation.PresentationNode.defaultInstance,
        bindings: const {},
        budget: portable_expression.EvaluationBudget.defaultInstance,
      );

  final EditOwner owner;
  final VoidCallback? onDispose;
  final PortablePresentationDocument _document;
  bool _disposed = false;

  @override
  PortablePresentationCapabilities get capabilities =>
      const PortablePresentationCapabilities();

  @override
  PortablePresentationDocument get document => _document;

  @override
  bool get enabled => true;

  @override
  bool get readOnly => owner.readOnly;

  @override
  Future<PortablePresentationWriteResult> execute(
    portable_action.EditorAction editorAction,
  ) async => const PortablePresentationWriteResult.rejected(
    "This test host has no actions",
  );

  @override
  portable_types.TypeUse? expectedType(portable_binding.BindingRef reference) =>
      null;

  @override
  portable_types.ValueLocation? location(
    portable_binding.BindingRef reference,
  ) => null;

  @override
  portable_types.DataValue? read(portable_binding.BindingRef reference) => null;

  @override
  Future<PortablePresentationWriteResult> write(
    portable_binding.BindingRef reference,
    portable_types.DataValue value,
  ) async => const PortablePresentationWriteResult.rejected(
    "This test host has no bindings",
  );

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    onDispose?.call();
    super.dispose();
  }
}

_Identifier _identifier(
  String id,
  DataValue value, {
  TypeExpression rootType = const StringType(),
  EditorMutationResult mutation = const EditorMutationResult.applied(
    StringValue("updated"),
  ),
  List<_TestSurfaceSpec> surfaceSpecs = const [_TestSurfaceSpec("value")],
}) => _Identifier(
  id: id,
  rootType: rootType,
  current: value,
  mutation: mutation,
  surfaceSpecs: surfaceSpecs,
);

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
