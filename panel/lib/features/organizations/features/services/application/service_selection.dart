part of "services.dart";

const serviceInspectorTypeRef = ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "panel", name: "Service"),
  revision: 2,
);

final _serviceInspectorType = TypeDefinition(
  id: serviceInspectorTypeRef,
  kind: NominalTypeKind.concrete,
  representation: RecordType(
    fields: {
      "version": const TypeField(name: "version", type: StringType()),
      "state": const TypeField(name: "state", type: StringType()),
      "lastSeen": TypeField(
        name: "lastSeen",
        type: NamedType(standardTypeRefs.optionOf(const TimestampType())),
      ),
    },
  ),
);

final _serviceInspectorCatalog = panelPresentationTypeCatalog([
  _serviceInspectorType,
]);

/// Stable selection identity for a canonical organization service.
///
/// Resolution waits for canonical and projected state, then builds an
/// inspector with canonical mutation revision and projected display values.
class ServiceIdentifier extends SelectableIdentifier {
  ServiceIdentifier(this.serviceId);

  final skir.RecordId serviceId;

  @override
  String get id => serviceId.id;
  @override
  Object get resourceId => serviceId;

  @override
  AsyncValue<Selectable> create(Ref ref) {
    final connections = ref.watch(serviceConnectionsProvider);
    final organization = ref.watch(organizationIdProvider);
    if (organization == null) {
      return AsyncError(ApiException.noOrganization(), StackTrace.current);
    }
    final repository = ref.watch(
      canonicalOrganizationServicesProvider(organization).notifier,
    );
    final canonicalState = ref.watch(canonicalServiceProvider(serviceId));
    if (canonicalState.mapUnready<Selectable>() case final value?) return value;
    final canonical = canonicalState.requireValue;
    if (canonical == null) {
      return AsyncError(SelectableNotFoundException(this), StackTrace.current);
    }

    final projectedState = ref.watch(projectedServiceProvider(serviceId));
    if (projectedState.mapUnready<Selectable>() case final value?) return value;
    final service = projectedState.requireValue;
    if (service == null) {
      return AsyncError(SelectableNotFoundException(this), StackTrace.current);
    }

    return AsyncData(
      ServiceSelectable(
        editTarget: serviceIdentityTarget(
          id: this,
          service: canonical,

          repository: ref
              .watch(resourceRepositoriesProvider)
              .services(organization),
        ),
        onUnbind: () => repository.deleteService(serviceId),
        id: this,
        service: service,
        canonicalService: canonical,
        connected: connections[serviceId] ?? false,
      ),
    );
  }

  @override
  int get hashCode => serviceId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceIdentifier && other.serviceId == serviceId;

  @override
  String toString() => "ServiceIdentifier(id: $serviceId)";
}

/// Inspector model joining service identity, runtime observation, and commands.
///
/// The identity editor owns rename commits. Unbind remains a separate service
/// operation, so displaying a projected name cannot mutate canonical state.
class ServiceSelectable extends InspectableSelectable<ServiceIdentifier> {
  const ServiceSelectable({
    required this.editTarget,
    required this.onUnbind,
    required this.id,
    required this.service,
    required this.canonicalService,
    required this.connected,
  });

  @override
  final ServiceIdentifier id;
  final Service service;
  final Service canonicalService;
  final bool connected;
  final EditorTarget editTarget;
  final Future<void> Function() onUnbind;

  RecordValue get _data => canonicalService.observationValue(connected);

  @override
  String get name => service.displayName;

  @override
  PresentationModel buildPresentation(
    EditorOwnerScope owners,
  ) => PresentationModel(
    catalog: _serviceInspectorCatalog,
    inputs: {
      const BindingId(0): PresentationInput.value(
        type: NamedType(serviceInspectorTypeRef),
        value: EditorValue.ready(_data),
      ),
      const BindingId(1): PresentationInput.edit(owners.editor(editTarget)),
    },
    presentations: [serviceInspectorPresentation(service)],
    root: PresentationNode(
      id: "service",
      element: PresentationInvocationElement(
        presentationId: _serviceInspectorPresentationId,
        arguments: {
          const BindingId(0): const BindingReference(bindingId: BindingId(0)),
          const BindingId(1): const BindingReference(bindingId: BindingId(1)),
        },
      ),
    ),
  );

  @override
  List<SelectionCapability> get capabilities => [
    UnbindSelectionCapability(onUnbind: onUnbind),
  ];

  @override
  InspectionContent buildInspection(EditorOwnerScope owners) =>
      InspectionContent(
        model: buildPresentation(owners),
        header: ManagedInspectorHeader(
          id: service.serviceId.id,
          owner: owners.editor(editTarget),
          fallbackName: service.displayName,
          fallbackColor: service.color,
          colorField: null,
        ),
      );
}

/// Projects service identity and connectivity into inspector fields.
///
/// Connectivity is an observation from the host heartbeat. It does not change
/// the canonical service identity or imply that a runtime configuration is
/// applied.
extension ServiceInspectorValue on Service {
  RecordValue observationValue(bool connected) => RecordValue({
    "version": role.version.asValue,
    "state": (connected ? "Connected" : "Offline").asValue,
    "lastSeen": _optionalTimestamp(lastSeen),
  });
}

final _serviceIdentityType = RecordType(
  fields: {"name": TypeField(name: "name", type: identifierStringType)},
);

/// Creates the scoped editor target used to rename [service].
///
/// The target snapshot is canonical even when the inspector displays a local
/// draft, preserving optimistic revision checks at commit time.
ResourceEditorTarget serviceIdentityTarget({
  required ServiceIdentifier id,
  required Service service,
  required ServiceResourceRepository repository,
}) => ResourceEditorTarget(
  targetId: id,
  label: "${service.displayName}: identity",
  resource: ServiceEditorResource(repository, service.serviceId),
  snapshot: serviceEditorSnapshot(service),
);
