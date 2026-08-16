part of "services.dart";

const serviceCollectionSourceId = PresentationCollectionSourceId(
  "organization.services",
);
const serviceRunsInRelationId = PresentationCollectionRelationId("runsIn");
const serviceCollectionRowBindingId = BindingId(50);

final serviceReferenceType = NamedType(
  standardTypeRefs.refTo(NamedType(serviceInspectorTypeRef)),
);
final serviceOptionReferenceType = NamedType(
  standardTypeRefs.optionOf(serviceReferenceType),
);

final serviceCollectionRowType = RecordType(
  fields: {
    "key": TypeField(name: "key", type: serviceReferenceType),
    "name": TypeField(name: "name", type: StringType()),
    "roles": TypeField(
      name: "roles",
      type: ListType(element: StringType()),
    ),
    "selection": TypeField(name: "selection", type: serviceOptionReferenceType),
    "runsIn": TypeField(
      name: "runsIn",
      type: ListType(element: serviceReferenceType),
    ),
    "selectable": TypeField(name: "selectable", type: BooleanType()),
    "unavailableReason": TypeField(
      name: "unavailableReason",
      type: NamedType(standardTypeRefs.optionOf(const StringType())),
    ),
  },
);

final serviceCollectionSchema = PresentationCollectionSchema(
  rowType: serviceCollectionRowType,
  keyType: serviceReferenceType,
  rowBindingId: serviceCollectionRowBindingId,
  key: _serviceRowField("key", serviceReferenceType),
  relations: [
    PresentationCollectionRelation(
      id: serviceRunsInRelationId,
      targets: _serviceRowField(
        "runsIn",
        ListType(element: serviceReferenceType),
      ),
    ),
  ],
);

PresentationCollectionSource servicePresentationCollection(
  Iterable<Service> services, {
  required Service editingService,
}) {
  final values = services.toList(growable: false);
  return LocalPresentationCollectionSource(
    id: serviceCollectionSourceId,
    schema: serviceCollectionSchema,
    rows: [
      _standaloneServiceRow,
      for (final service in values)
        _serviceCollectionRow(
          service,
          unavailableReason: _serviceUnavailableReason(
            values,
            editingService: editingService,
            candidate: service,
          ),
        ),
    ],
    registry: TypeRegistry(TypeCatalog([_serviceInspectorType])),
    searchPredicate: (row, query) {
      if (row is! RecordValue) return false;
      final name = row.fields["name"];
      return name is StringValue &&
          name.value.toLowerCase().contains(
            query.normalizedQuery.toLowerCase(),
          );
    },
  );
}

final _standaloneServiceRow = RecordValue({
  "key": const StringValue("standalone"),
  "name": const StringValue("Standalone"),
  "roles": const ListValue([]),
  "selection": _serviceOptionalReference(null),
  "runsIn": const ListValue([]),
  "selectable": const BooleanValue(true),
  "unavailableReason": _serviceOptionalText(null),
});

RecordValue _serviceCollectionRow(
  Service service, {
  required String? unavailableReason,
}) => RecordValue({
  "key": StringValue(service.serviceId.id),
  "name": StringValue(service.displayName),
  "roles": ListValue(
    service.roles.map((role) => StringValue(role.label)).toList(),
  ),
  "selection": _serviceOptionalReference(service.serviceId),
  "runsIn": ListValue([
    if (service.runsIn case final runsIn?) StringValue(runsIn.id),
  ]),
  "selectable": BooleanValue(unavailableReason == null),
  "unavailableReason": _serviceOptionalText(unavailableReason),
});

String? _serviceUnavailableReason(
  List<Service> services, {
  required Service editingService,
  required Service candidate,
}) {
  if (candidate.organization != editingService.organization) {
    return "The service belongs to another organization";
  }
  if (!candidate.isRealm) return "Runs in requires a Realm service";
  if (candidate.serviceId == editingService.serviceId) {
    return "A service cannot run in itself";
  }
  final byId = {for (final service in services) service.serviceId: service};
  var current = candidate.runsIn;
  final visited = <skir.RecordId>{};
  while (current != null && visited.add(current)) {
    if (current == editingService.serviceId) {
      return "This selection would create a cycle";
    }
    current = byId[current]?.runsIn;
  }
  if (current != null) return "The service hierarchy contains a cycle";
  return null;
}

DataValue _serviceOptionalReference(skir.RecordId? value) => _optionalValue(
  value,
  serviceReferenceType,
  encode: (recordId) => StringValue(recordId.id),
);

DataValue _serviceOptionalText(String? value) =>
    _optionalValue(value, const StringType(), encode: StringValue.new);

TypedExpression _serviceRowField(String name, TypeExpression type) =>
    TypedExpression(
      resultType: type,
      expression: BindingExpression(
        BindingReference(
          bindingId: serviceCollectionRowBindingId,
          path: DataPath.root.field(name),
        ),
      ),
    );
