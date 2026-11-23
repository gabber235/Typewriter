import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Authored [resources] of catalog [generation] without links, for code
/// that looks resources up by id; it reads no values by location.
final class AuthoredRecords implements PortableAuthoringView {
  AuthoredRecords(this.generation, this.resources);

  @override
  final skir.CatalogGeneration generation;

  @override
  final Map<skir.ResourceId, skir.AuthoringRecord> resources;

  @override
  List<skir.LinkProjection> get links => const [];

  @override
  skir.AuthoringRecord? resource(skir.ResourceId id) => resources[id];

  @override
  PortablePathResult<skir.DataValue> read(skir.ValueLocation location) =>
      const PortablePathUnavailable("Authored records are read by resource");

  @override
  skir.DataValue defaultValue(skir.TypeUse? type) => skir.DataValue.unfilled;
}

/// [record] storing [value] in its field [name], whether it stored that field
/// or left it unset.
skir.AuthoringRecord withField(
  skir.AuthoringRecord record,
  String name,
  skir.DataValue value,
) => withFields(record, {name: value});

/// [record] storing each of [fields], whether it stored that field or left it
/// unset.
skir.AuthoringRecord withFields(
  skir.AuthoringRecord record,
  Map<String, skir.DataValue> fields,
) => skir.AuthoringRecord(
  types: const [],
  configuration: record.configuration,
  fields: [
    for (final field in record.fields)
      if (!fields.containsKey(field.name)) field,
    for (final field in fields.entries)
      skir.FieldValue(name: field.key, value: field.value),
  ],
);

/// [resource] as [id] storing each of [fields]. Its unset values stay: a
/// document reads an unset value only while the field is not stored.
skir.AuthoringResource storing(
  skir.AuthoringResource resource,
  skir.ResourceId id,
  Map<String, skir.DataValue> fields,
) => skir.AuthoringResource(
  id: id,
  content: withFields(resource.content, fields),
  unset: resource.unset,
);
