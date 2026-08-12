part of "services.dart";

const _serviceInspectorType = TypeDefinition(
  id: ResolvedTypeRef(
    id: QualifiedTypeId(namespace: "panel", name: "Service"),
    revision: 1,
  ),
  kind: NominalTypeKind.concrete,
  representation: RecordType(
    fields: {"name": TypeField(name: "name", type: StringType())},
  ),
);

const _serviceInspectorCatalog = TypeCatalog([_serviceInspectorType]);

class ServiceIdentifier extends SelectableIdentifier {
  ServiceIdentifier(this.serviceId);

  final skir.RecordId serviceId;

  @override
  String get id => serviceId.id;

  @override
  AsyncValue<Selectable> create(Ref ref) =>
      ref.watch(serviceProvider(serviceId)).whenData((value) {
        if (value == null) throw SelectableNotFoundException(this);
        return ServiceSelectable(ref: ref, id: this, service: value);
      });

  @override
  int get hashCode => serviceId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceIdentifier && other.serviceId == serviceId;

  @override
  String toString() => "ServiceIdentifier(id: $serviceId)";
}

class ServiceSelectable extends InspectableSelectable<ServiceIdentifier> {
  ServiceSelectable({
    required this.ref,
    required this.id,
    required this.service,
  });

  @override
  final ServiceIdentifier id;
  final Service service;
  final Ref ref;

  @override
  String get name => service.displayName;

  @override
  ResolvedTypeRef get rootType => _serviceInspectorType.id;

  @override
  TypeCatalog get typeCatalog => _serviceInspectorCatalog;

  @override
  List<SelectionCapability> get capabilities => [
    if (service.isOnline && service.organization != null)
      OpenSelectionCapability(
        onOpen: () => ref
            .read(appRouterProvider)
            .navigate(
              OrganizationRoute(
                organizationId: service.organization!.id,
                children: [RealmRoute(realmId: service.serviceId.id)],
              ),
            ),
        allowMultiSelect: false,
      ),
    UnbindSelectionCapability(
      onUnbind: () =>
          ref.read(servicesProvider.notifier).deleteService(service.serviceId),
    ),
  ];

  @override
  Widget? buildInspectorHeader() => ServiceHeader(
    id: service.serviceId.id,
    name: service.displayName,
    color: service.color,
  );

  @override
  EditorValue value(DataPath path) =>
      RecordValue({"name": StringValue(service.name)}).readEditorValue(path);

  @override
  EditorMutationResult update(DataPath path, DataValue value) {
    final result = validateUpdate(path, value);
    if (result is! AppliedEditorMutation || value is! StringValue) {
      return result;
    }
    ref
        .read(servicesProvider.notifier)
        .updateService(service.copyWith(name: value.value));
    return result;
  }

  @override
  int get hashCode => Object.hash(id, service);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceSelectable && other.id == id && other.service == service;
}
