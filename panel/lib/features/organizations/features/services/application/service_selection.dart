part of "services.dart";

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
    final repository = ref
        .watch(resourceRepositoriesProvider)
        .services(organization);
    final work = ref.watch(localWorkProvider.notifier);
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
          connected: connections[serviceId] ?? false,
          repository: repository,
          work: work,
        ),
        onUnbind: () async {
          final response = await work.execute(repository.unbind(serviceId));
          response.requireAcceptedUnbinding();
        },
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
  final ValueEditingRegistration editTarget;
  final Future<void> Function() onUnbind;

  @override
  List<PortableMultiInspectionSurface> get portableMultiInspectionSurfaces => [
    _ServiceIdentityPortableSurface(editTarget),
  ];

  @override
  String get name => service.displayName;

  @override
  List<SelectionCapability> get capabilities => [
    UnbindSelectionCapability(onUnbind: onUnbind),
  ];

  @override
  InspectionContent buildInspection(InspectionBindingScope owners) =>
      InspectionContent(
        host: service.portablePresentationHost(
          connected: connected,
          identityOwner: owners.editor(editTarget),
        ),
      );
}

final class _ServiceIdentityPortableSurface
    implements PortableMultiInspectionSurface {
  const _ServiceIdentityPortableSurface(this.target);

  @override
  Object get id => "service.identity";

  @override
  final ValueEditingRegistration target;

  @override
  skir.TypeUse get rootType => _serviceIdentityType;

  @override
  CheckedEditorCatalog get catalog => _serviceIdentityCatalog;

  @override
  bool isCompatibleWith(PortableMultiInspectionSurface other) =>
      other is _ServiceIdentityPortableSurface;

  @override
  PortablePresentationHost buildHost(
    List<PortableMultiInspectionSurface> members,
    EditOwner combinedOwner,
  ) => serviceIdentityPortablePresentationHost(identityOwner: combinedOwner);
}

final _serviceIdentityDefinition = _draftType("ServiceIdentity");
final _serviceIdentityType = skir.TypeUse.wrapNamed(
  _draftUse(_serviceIdentityDefinition),
);
final _serviceIdentityCatalog = skir.EditorCatalog(
  resourceDisplays: const [],
  resourceOperations: const [],
  generation: skir.CatalogGeneration(value: "panel.service.identity"),
  types: [
    _draftPublished(
      _serviceIdentityDefinition,
      fields: [
        _draftField(
          _serviceIdentityDefinition,
          "name",
          _hostConfigurationTextTemplate,
        ),
      ],
    ),
  ],
  presentations: const [],
  presentationMaterials: const [],
  configuration: const [],
  capabilities: const [],
  relations: const [],
  endpointBindings: const [],
  realmRoot: skir.TypeDefinitionId.defaultInstance,
  recommendations: const [],
  roleFallbacks: const [],

  diagnostics: const [],
).asTrustedLocalCatalog();

/// Creates the scoped editor target used to rename [service].
///
/// The target snapshot is canonical even when the inspector displays a local
/// draft, preserving optimistic revision checks at commit time.
ValueEditingRegistration serviceIdentityTarget({
  required ServiceIdentifier id,
  required Service service,
  required bool connected,
  required ServiceResourceRepository repository,
  LocalWork? work,
}) => ValueEditingRegistration(
  targetId: id,
  label: "${service.displayName}: identity",
  persistence: ServiceEditPersistence(repository, service.serviceId),
  snapshot: service.editorSnapshot,
  observe: work == null
      ? null
      : (workspace) => work.observe(
          canonicalOrganizationServicesProvider(repository.organization),
          (next) {
            if (next.value case final values?) {
              final current = values.firstWhereOrNull(
                (value) => value.serviceId == service.serviceId,
              );
              workspace.acceptConfirmed(
                current == null
                    ? workspace.confirmed.copyWith(exists: false)
                    : ValueEditDocument.fromSnapshot(
                        current.editorSnapshot,
                        identity: workspace.confirmed.identity,
                      ),
              );
            } else if (next.error case final error?) {
              workspace.acceptFailure(error);
            }
          },
        ),
  portablePresentation: (source) => service.portablePresentationHost(
    connected: connected,
    identityOwner: source,
  ),
);
