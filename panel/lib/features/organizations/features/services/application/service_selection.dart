part of "services.dart";

const serviceInspectorTypeRef = ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "panel", name: "Service"),
  revision: 1,
);

const serviceRoleTypeRef = ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "panel", name: "ServiceRole"),
  revision: 1,
);

const engineRoleTypeRef = ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "panel", name: "EngineRole"),
  revision: 1,
);

const realmRoleTypeRef = ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "panel", name: "RealmRole"),
  revision: 1,
);

const customRoleTypeRef = ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "panel", name: "CustomRole"),
  revision: 1,
);

final _serviceReferenceType = NamedType(
  standardTypeRefs.refTo(NamedType(serviceInspectorTypeRef)),
);

final _serviceInspectorType = TypeDefinition(
  id: serviceInspectorTypeRef,
  kind: NominalTypeKind.concrete,
  defaultPresentationId: _serviceInspectorPresentationId,
  representation: RecordType(
    fields: {
      "name": TypeField(name: "name", type: identifierStringType),
      "runsIn": TypeField(
        name: "runsIn",
        type: NamedType(standardTypeRefs.optionOf(_serviceReferenceType)),
      ),
      "roles": TypeField(
        name: "roles",
        type: ListType(element: NamedType(serviceRoleTypeRef)),
      ),
    },
  ),
);

final serviceRoleTypes = [
  const TypeDefinition(
    id: serviceRoleTypeRef,
    kind: NominalTypeKind.sealedAbstract,
  ),
  TypeDefinition(
    id: engineRoleTypeRef,
    kind: NominalTypeKind.concrete,
    parents: [serviceRoleTypeRef],
    representation: const RecordType(
      fields: {"version": TypeField(name: "version", type: StringType())},
    ),
  ),
  TypeDefinition(
    id: realmRoleTypeRef,
    kind: NominalTypeKind.concrete,
    parents: [serviceRoleTypeRef],
    representation: const RecordType(
      fields: {"version": TypeField(name: "version", type: StringType())},
    ),
  ),
  TypeDefinition(
    id: customRoleTypeRef,
    kind: NominalTypeKind.concrete,
    parents: [serviceRoleTypeRef],
    representation: const RecordType(
      fields: {
        "name": TypeField(name: "name", type: StringType()),
        "version": TypeField(name: "version", type: StringType()),
      },
    ),
  ),
];

final _serviceInspectorCatalog = TypeCatalog([
  _serviceInspectorType,
  ...serviceRoleTypes,
]);

class ServiceIdentifier extends SelectableIdentifier {
  ServiceIdentifier(this.serviceId);

  final skir.RecordId serviceId;

  @override
  String get id => serviceId.id;

  @override
  AsyncValue<Selectable> create(Ref ref) {
    final services = ref.watch(servicesProvider).value ?? const <Service>[];
    return ref.watch(serviceProvider(serviceId)).whenData((value) {
      if (value == null) throw SelectableNotFoundException(this);
      return ServiceSelectable(
        ref: ref,
        id: this,
        service: value,
        serviceCollection: servicePresentationCollection(
          services,
          editingService: value,
        ),
      );
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
    required this.serviceCollection,
  });

  @override
  final ServiceIdentifier id;
  final Service service;
  final Ref ref;
  final PresentationCollectionSource serviceCollection;

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
    collections: [serviceCollection],
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
    final readOnlyFields = {"roles"};
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
    final runsInPath = DataPath.root.field("runsIn");
    if (path == runsInPath && !service.isEngine && !service.isCustom) {
      return EditorMutationResult.invalid([
        TypeDiagnostic(
          code: TypeDiagnosticCode.invalidPath,
          message: "Runs in is not applicable to this service",
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
    final runsIn = value.fields["runsIn"];
    if (name is! StringValue || name.value.trim().isEmpty || runsIn == null) {
      return null;
    }
    final decodedRunsIn = _decodeOptionalReference(runsIn);
    if (!decodedRunsIn.$1) return null;
    return service.copyWith(
      revision: expectedRevision,
      name: name.value,
      runsIn: decodedRunsIn.$2,
    );
  }
}

(bool, skir.RecordId?) _decodeOptionalReference(DataValue value) {
  if (value case PolymorphicValue(
    concreteType: final type,
    value: UnitValue(),
  ) when type == standardTypeRefs.noneOf(_serviceReferenceType)) {
    return (true, null);
  }
  if (value case PolymorphicValue(
    concreteType: final type,
    value: RecordValue(fields: {"value": StringValue(:final value)}),
  ) when type == standardTypeRefs.someOf(_serviceReferenceType)) {
    return (true, _decodeServiceReference(value));
  }
  return (false, null);
}

extension ServiceInspectorValue on Service {
  RecordValue get inspectorValue => RecordValue({
    "name": StringValue(name),
    "runsIn": _optionalValue(
      runsIn,
      _serviceReferenceType,
      encode: (runsIn) => StringValue(_encodeServiceReference(runsIn)),
    ),
    "roles": ListValue(roles.map((role) => role.inspectorValue).toList()),
  });
}

extension on ServiceRole {
  DataValue get inspectorValue => switch (this) {
    EngineServiceRole(:final version) => PolymorphicValue(
      concreteType: engineRoleTypeRef,
      value: RecordValue({"version": StringValue(version)}),
    ),
    RealmServiceRole(:final version) => PolymorphicValue(
      concreteType: realmRoleTypeRef,
      value: RecordValue({"version": StringValue(version)}),
    ),
    CustomServiceRole(:final name, :final version) => PolymorphicValue(
      concreteType: customRoleTypeRef,
      value: RecordValue({
        "name": StringValue(name),
        "version": StringValue(version),
      }),
    ),
    ServiceRole() => throw StateException("Unsupported role type: $this"),
  };
}

DataValue _optionalValue<T>(
  T? item,
  TypeExpression valueType, {
  required DataValue Function(T item) encode,
}) {
  if (item == null) {
    return PolymorphicValue(
      concreteType: standardTypeRefs.noneOf(valueType),
      value: const UnitValue(),
    );
  }
  return PolymorphicValue(
    concreteType: standardTypeRefs.someOf(valueType),
    value: RecordValue({"value": encode(item)}),
  );
}
