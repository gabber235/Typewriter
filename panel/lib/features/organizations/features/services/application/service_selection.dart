part of "services.dart";

const serviceInspectorTypeRef = ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "panel", name: "Service"),
  revision: 1,
);

final _serviceInspectorType = TypeDefinition(
  id: serviceInspectorTypeRef,
  kind: NominalTypeKind.concrete,
  defaultPresentationId: _serviceInspectorPresentationId,
  representation: RecordType(
    fields: {
      "name": TypeField(name: "name", type: identifierStringType),
      "version": const TypeField(name: "version", type: StringType()),
      "state": const TypeField(name: "state", type: StringType()),
      "lastSeen": const TypeField(name: "lastSeen", type: StringType()),
    },
  ),
);

final _serviceInspectorCatalog = TypeCatalog([_serviceInspectorType]);

class ServiceIdentifier extends SelectableIdentifier {
  ServiceIdentifier(this.serviceId);

  final skir.RecordId serviceId;

  @override
  String get id => serviceId.id;

  @override
  AsyncValue<Selectable> create(Ref ref) {
    return ref.watch(serviceProvider(serviceId)).whenData((value) {
      if (value == null) throw SelectableNotFoundException(this);
      return ServiceSelectable(ref: ref, id: this, service: value);
    });
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

  RecordValue get _data => service.inspectorValue;

  @override
  String get name => service.displayName;

  @override
  EditorDocument get document => EditorDocument(
    rootType: NamedType(serviceInspectorTypeRef),
    typeCatalog: _serviceInspectorCatalog,
    confirmedValue: _data,
    revision: service.revision,
    presentations: [serviceInspectorPresentation(service)],
  );

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
  EditorMutationResult validate(DataPath path, DataValue value) {
    const readOnlyFields = {"version", "state", "lastSeen"};
    if (path.segments.firstOrNull case FieldPathSegment(
      :final name,
    ) when readOnlyFields.contains(name)) {
      return EditorMutationResult.invalid([
        TypeDiagnostic(
          code: TypeDiagnosticCode.invalidPath,
          message: "Service status fields are read only",
          path: path,
        ),
      ]);
    }
    return super.validate(path, value);
  }

  @override
  Future<TypedMutationResult> commit(EditorCommit commit) {
    final next = _serviceFromInspectorValue(
      commit.rootValue,
      expectedRevision: commit.expectedRevision,
    );
    if (next == null) {
      return Future.value(
        TypedMutationResult.invalid([
          const TypeDiagnostic(
            code: TypeDiagnosticCode.invalidValue,
            message: "The Service inspector value is invalid",
          ),
        ]),
      );
    }
    return ref.read(servicesProvider.notifier).updateService(next);
  }

  @override
  int get hashCode => Object.hash(id, service);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceSelectable && other.id == id && other.service == service;

  Service? _serviceFromInspectorValue(
    DataValue value, {
    required int expectedRevision,
  }) {
    if (value is! RecordValue) return null;
    final name = value.fields["name"];
    if (name is! StringValue || name.value.trim().isEmpty) {
      return null;
    }
    return service.copyWith(revision: expectedRevision, name: name.value);
  }
}

extension ServiceInspectorValue on Service {
  RecordValue get inspectorValue => RecordValue({
    "name": StringValue(name),
    "version": StringValue(role.version),
    "state": StringValue(isOnline ? "Connected" : "Offline"),
    "lastSeen": StringValue(lastSeenLabel),
  });
}
