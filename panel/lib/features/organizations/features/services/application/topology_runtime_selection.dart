part of "services.dart";

/// Exposes Realm deployment state through the shared inspector presentation.
///
/// Realm runtime data is observational. Opening the Realm is available only
/// while the owner host service is connected, because all Realm operations use
/// that service connection.
class _RealmInstanceSelectable
    extends InspectableSelectable<RealmInstanceIdentifier> {
  _RealmInstanceSelectable({
    required this.ref,
    required this.id,
    required this.realm,
    required this.host,
    required this.service,
  });

  final Ref ref;
  @override
  final RealmInstanceIdentifier id;
  final TopologyRealm realm;
  final TopologyHost? host;
  final Service? service;

  bool get canOpen => host != null && (service?.isOnline ?? false);

  @override
  String get name => realm.ownerHost.name.formatted;

  @override
  EditorDocument get document => EditorDocument(
    rootType: NamedType(_realmInstanceInspectorTypeRef),
    typeCatalog: _realmInstanceInspectorCatalog,
    confirmedValue: _runtimeValue(
      ownerHost: realm.ownerHost.name.formatted,
      target: realm.targetEngine,
      state: realm.state,
    ),
    revision: realm.revision,
    presentations: [_realmInstanceInspectorPresentation],
  );

  @override
  List<SelectionCapability> get capabilities => [
    if (canOpen)
      OpenSelectionCapability(onOpen: _open, allowMultiSelect: false),
  ];

  void _open() {
    final organization = service?.organization;
    if (!canOpen || organization == null) return;
    ref
        .read(appRouterProvider)
        .navigate(realmNavigationRoute(organization, realm.realmId));
  }

  @override
  Widget? buildInspectorHeader() => ServiceHeader(
    id: realm.realmId.id,
    name: name,
    color: realmServiceRoleColor,
  );

  @override
  EditorMutationResult validate(DataPath path, DataValue value) =>
      _readOnlyRuntimeMutation(path);

  @override
  Future<TypedMutationResult> commit(EditorCommit commit) =>
      Future.value(invalidMutation("Realm runtime state is read only"));
}

OrganizationRoute realmNavigationRoute(
  skir.RecordId organizationId,
  skir.RecordId realmId,
) => OrganizationRoute(
  organizationId: organizationId.id,
  children: [RealmRoute(realmId: realmId.id)],
);

/// Exposes execution engine deployment state through the shared inspector.
///
/// Engine instances are controlled through their owner host configuration, so
/// their own inspector remains read only and reports assignment and lifecycle
/// state without creating a second mutation path.
class _EngineInstanceSelectable
    extends InspectableSelectable<EngineInstanceIdentifier> {
  _EngineInstanceSelectable({
    required this.id,
    required this.engine,
    required this.host,
    required this.service,
  });

  @override
  final EngineInstanceIdentifier id;
  final TopologyEngine engine;
  final TopologyHost? host;
  final Service? service;

  @override
  String get name => "${engine.target.engineId.formatted} engine";

  @override
  EditorDocument get document => EditorDocument(
    rootType: NamedType(_engineInstanceInspectorTypeRef),
    typeCatalog: _engineInstanceInspectorCatalog,
    confirmedValue: _runtimeValue(
      ownerHost: engine.ownerHost.name.formatted,
      target: engine.target,
      state: engine.state,
      assignedRealm: engine.realm.ownerHost.name.formatted,
    ),
    revision: engine.revision,
    presentations: [_engineInstanceInspectorPresentation],
  );

  @override
  List<SelectionCapability> get capabilities => [];

  @override
  Widget? buildInspectorHeader() => ServiceHeader(
    id: engine.engineId.id,
    name: name,
    color: engineServiceRoleColor,
  );

  @override
  EditorMutationResult validate(DataPath path, DataValue value) =>
      _readOnlyRuntimeMutation(path);

  @override
  Future<TypedMutationResult> commit(EditorCommit commit) =>
      Future.value(invalidMutation("Engine runtime state is read only"));
}

RecordValue _runtimeValue({
  required String ownerHost,
  required TopologyEngineTarget target,
  required TopologyRuntimeState state,
  String? assignedRealm,
}) => RecordValue({
  _RuntimeInspectorFields.ownerHost: StringValue(ownerHost),
  if (assignedRealm != null)
    _RuntimeInspectorFields.assignedRealm: StringValue(assignedRealm),
  _RuntimeInspectorFields.target: StringValue(_targetLabel(target)),
  _RuntimeInspectorFields.runtimeStatus: StringValue(
    childRuntimeStatusLabel(state.status),
  ),
  _RuntimeInspectorFields.artifactVersion: StringValue(
    state.activeArtifactVersion ?? "None",
  ),
  _RuntimeInspectorFields.runtimeMessage: StringValue(state.message ?? "None"),
  _RuntimeInspectorFields.updatedAt: TimestampValue(state.updatedAt),
});

EditorMutationResult _readOnlyRuntimeMutation(DataPath path) =>
    EditorMutationResult.invalid([
      TypeDiagnostic(
        code: TypeDiagnosticCode.invalidPath,
        message: "Runtime state is read only",
        path: path,
      ),
    ]);
