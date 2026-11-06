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

/// [record] with its field [name] holding [value] instead.
skir.AuthoringRecord withField(
  skir.AuthoringRecord record,
  String name,
  skir.DataValue value,
) => skir.AuthoringRecord(
  types: const [],
  configuration: record.configuration,
  fields: [
    for (final field in record.fields)
      if (field.name == name)
        skir.FieldValue(name: name, value: value)
      else
        field,
  ],
);
