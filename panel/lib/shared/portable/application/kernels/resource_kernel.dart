import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The panel's authored resource operations. Every resource they read goes
/// through [skir.PortableResources], which records it as a read; a resource
/// that is absent, or no longer of the expected kind, is missing at its root.
final class PanelResourceKernel implements skir.ResourceKernel {
  const PanelResourceKernel();

  @override
  skir.PortableMaybe<skir.DataValue> configuration(
    skir.ResourceId identity,
    skir.PortableResources resources,
  ) => switch (resources.resource(identity)) {
    final record? => skir.PortableMaybeValue(
      typeSelectionReadValue(record.configuration),
    ),
    null => skir.PortableMaybeMissing([_root(identity)]),
  };

  @override
  skir.PortableMaybe<skir.ResourceId> identity(
    skir.LinkValue reference,
    skir.PortableResources resources,
  ) => _linked(reference, resources).map((_) => reference.target.resource);

  @override
  skir.PortableMaybe<skir.DataValue> value(
    skir.LinkValue reference,
    skir.PortableResources resources,
  ) => _linked(reference, resources).map(_configuredValue);

  @override
  skir.PortableMaybe<skir.DataValue> valueOf(
    skir.ResourceId identity,
    skir.TypeUse tType,
    skir.PortableResources resources,
  ) {
    final record = resources.resource(identity);
    if (record == null || !resources.selects(record.configuration, tType)) {
      return skir.PortableMaybeMissing([_root(identity)]);
    }
    return skir.PortableMaybeValue(_configuredValue(record));
  }
}

/// The record a link targets, or missing when the link is stale: its resource
/// is gone or no longer belongs to the family its relation targets.
skir.PortableMaybe<skir.AuthoringRecord> _linked(
  skir.LinkValue reference,
  skir.PortableResources resources,
) {
  final identity = reference.target.resource;
  final record = resources.resource(identity);
  if (record == null ||
      !resources.linkTargets(reference, record.configuration)) {
    return skir.PortableMaybeMissing([_root(identity)]);
  }
  return skir.PortableMaybeValue(record);
}

/// The configured value of [record]: its fields as a record, named by its
/// type once the configuration is complete.
skir.DataValue _configuredValue(skir.AuthoringRecord record) {
  final payload = skir.DataValue.createRecord(fields: record.fields);
  return switch (record.configuration) {
    skir.TypeSelection_completeWrapper(:final value) =>
      skir.DataValue.createNamed(actualType: value, payload: payload),
    _ => payload,
  };
}

skir.ValueLocation _root(skir.ResourceId identity) =>
    skir.ValueLocation(resource: identity, path: editorRootPath);
