import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:typewriter_panel/typewriter_panel.dart"
    show CheckedEditorCatalog, admitsPortableScalarValue;

/// Applies the checked portable schema before a backend codec receives a write.
extension PortableValueAdmission on CheckedEditorCatalog {
  bool admitsPortableValue(types.TypeUse expected, types.DataValue value) =>
      _admitsPortableValue(this, expected, value, 0);

  types.DataValue? admitPortablePayloadAt(
    types.TypeSelection root,
    types.ValuePath path,
    types.DataValue payload,
  ) {
    final expected = valueTypeAt(root, path);
    if (expected == null) return null;
    final actual = switch (payload) {
      final value
          when value == types.DataValue.unfilled ||
              value == types.DataValue.null_ =>
        value,
      _ => switch (namedUse(expected)) {
        final named? => types.DataValue.createNamed(
          actualType: named,
          payload: payload,
        ),
        null => payload,
      },
    };
    return admitsPortableValue(expected, actual) ? actual : null;
  }
}

bool _admitsPortableValue(
  CheckedEditorCatalog catalog,
  types.TypeUse expected,
  types.DataValue value,
  int depth,
) {
  if (depth > _maximumPortableValueDepth || value == types.DataValue.unknown) {
    return false;
  }
  if (value == types.DataValue.unfilled) return true;
  if (expected case types.TypeUse_nullableWrapper(value: final nullable)) {
    return value == types.DataValue.null_ ||
        _admitsPortableValue(catalog, nullable.value, value, depth + 1);
  }
  if (value == types.DataValue.null_) return false;
  return switch (expected) {
    types.TypeUse_scalarWrapper(value: final scalar) =>
      admitsPortableScalarValue(scalar, value),
    types.TypeUse_namedWrapper(value: final named) => _admitsNamed(
      catalog,
      named,
      value,
      depth + 1,
    ),
    _ => false,
  };
}

bool _admitsNamed(
  CheckedEditorCatalog catalog,
  types.NamedTypeUse expected,
  types.DataValue value,
  int depth,
) {
  final named = switch (value) {
    types.DataValue_namedWrapper(:final value) => value,
    _ => null,
  };
  if (named == null) return false;
  if (!catalog.isReadyApplication(named.actualType) ||
      !catalog.isReadyApplication(expected)) {
    return false;
  }
  if (!catalog.isReadableAs(
    types.TypeUse.wrapNamed(named.actualType),
    types.TypeUse.wrapNamed(expected),
  )) {
    return false;
  }
  final published = catalog.published(named.actualType.definition)!;
  final selection = types.TypeSelection.wrapComplete(named.actualType);
  return _admitsPayload(
    catalog,
    selection,
    published.definition.representation,
    named.payload,
    depth + 1,
  );
}

bool _admitsPayload(
  CheckedEditorCatalog catalog,
  types.TypeSelection selection,
  types.RepresentationTemplate representation,
  types.DataValue value,
  int depth,
) {
  if (depth > _maximumPortableValueDepth || value == types.DataValue.unknown) {
    return false;
  }
  if (value == types.DataValue.unfilled) return true;
  return switch (representation) {
    types.RepresentationTemplate_scalarWrapper(value: final scalar) =>
      admitsPortableScalarValue(scalar.kind, value),
    types.RepresentationTemplate_recordWrapper() => _admitsRecord(
      catalog,
      selection,
      value,
      depth + 1,
    ),
    types.RepresentationTemplate_sequenceWrapper(value: final sequence) =>
      _admitsSequence(catalog, selection, sequence, value, depth + 1),
    types.RepresentationTemplate_mappingWrapper(value: final mapping) =>
      _admitsMapping(catalog, selection, mapping, value, depth + 1),
    types.RepresentationTemplate_enumerationWrapper(value: final enumeration) =>
      value is types.DataValue_enumCaseWrapper &&
          enumeration.cases.any((candidate) => candidate.key == value.value),
    types.RepresentationTemplate_linkWrapper(value: final link) =>
      value is types.DataValue_linkWrapper &&
          value.value.endpoint == link.endpoint,
    _ => false,
  };
}

bool _admitsRecord(
  CheckedEditorCatalog catalog,
  types.TypeSelection selection,
  types.DataValue value,
  int depth,
) {
  final record = switch (value) {
    types.DataValue_recordWrapper(:final value) => value,
    _ => null,
  };
  if (record == null) return false;
  final fields = catalog.fields(selection);
  if (fields.any((field) => field.type == null)) return false;
  final expected = {
    for (final field in fields) field.template.key: field.type!,
  };
  final actual = <String, types.DataValue>{};
  for (final field in record.fields) {
    if (actual.containsKey(field.name)) return false;
    actual[field.name] = field.value;
  }
  if (actual.length != expected.length ||
      !actual.keys.every(expected.containsKey)) {
    return false;
  }
  return actual.entries.every(
    (field) => _admitsPortableValue(
      catalog,
      expected[field.key]!,
      field.value,
      depth + 1,
    ),
  );
}

bool _admitsSequence(
  CheckedEditorCatalog catalog,
  types.TypeSelection selection,
  types.SequenceRepresentationTemplate representation,
  types.DataValue value,
  int depth,
) {
  final items = switch ((representation.kind, value)) {
    (final kind, types.DataValue_listValueWrapper(value: final payload))
        when kind == types.CollectionKind.list =>
      payload.items,
    (final kind, types.DataValue_setValueWrapper(value: final payload))
        when kind == types.CollectionKind.set_ =>
      payload.items,
    _ => null,
  };
  final itemType = catalog.applyTemplate(representation.item, selection);
  if (items == null || itemType == null) return false;
  final ids = <types.ItemId>{};
  for (final item in items) {
    if (!ids.add(item.id) ||
        !_admitsPortableValue(catalog, itemType, item.value, depth + 1)) {
      return false;
    }
  }
  return true;
}

bool _admitsMapping(
  CheckedEditorCatalog catalog,
  types.TypeSelection selection,
  types.MappingRepresentationTemplate representation,
  types.DataValue value,
  int depth,
) {
  final rows = switch (value) {
    types.DataValue_mapValueWrapper(:final value) => value.rows,
    _ => null,
  };
  final keyType = catalog.applyTemplate(representation.key, selection);
  final valueType = catalog.applyTemplate(representation.value, selection);
  if (rows == null || keyType == null || valueType == null) return false;
  final ids = <types.ItemId>{};
  for (final row in rows) {
    if (!ids.add(row.id) ||
        !_admitsPortableValue(catalog, keyType, row.key, depth + 1) ||
        !_admitsPortableValue(catalog, valueType, row.value, depth + 1)) {
      return false;
    }
  }
  return true;
}

const _maximumPortableValueDepth = 512;
