import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Applies the checked portable schema before a backend codec receives a write.
extension PortableValueAdmission on CheckedEditorCatalog {
  bool admitsPortableValue(skir.TypeUse expected, skir.DataValue value) =>
      _admitsPortableValue(this, expected, value, 0);

  skir.DataValue? admitPortablePayloadAt(
    skir.TypeSelection root,
    skir.ValuePath path,
    skir.DataValue payload,
  ) {
    final expected = valueTypeAt(root, path);
    if (expected == null) return null;
    final actual = switch (payload) {
      final value
          when value == skir.DataValue.unfilled ||
              value == skir.DataValue.null_ =>
        value,
      _ => switch (namedUse(expected)) {
        final named? => skir.DataValue.createNamed(
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
  skir.TypeUse expected,
  skir.DataValue value,
  int depth,
) {
  if (depth > _maximumPortableValueDepth || value == skir.DataValue.unknown) {
    return false;
  }
  if (value == skir.DataValue.unfilled) return true;
  if (expected case skir.TypeUse_nullableWrapper(value: final nullable)) {
    return value == skir.DataValue.null_ ||
        _admitsPortableValue(catalog, nullable.value, value, depth + 1);
  }
  if (value == skir.DataValue.null_) return false;
  return switch (expected) {
    skir.TypeUse_scalarWrapper(value: final scalar) =>
      admitsPortableScalarValue(scalar, value),
    skir.TypeUse_namedWrapper(value: final named) => _admitsNamed(
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
  skir.NamedTypeUse expected,
  skir.DataValue value,
  int depth,
) {
  final named = switch (value) {
    skir.DataValue_namedWrapper(:final value) => value,
    _ => null,
  };
  if (named == null) return false;
  if (!catalog.isReadyApplication(named.actualType) ||
      !catalog.isReadyApplication(expected)) {
    return false;
  }
  if (!catalog.isReadableAs(
    skir.TypeUse.wrapNamed(named.actualType),
    skir.TypeUse.wrapNamed(expected),
  )) {
    return false;
  }
  final published = catalog.published(named.actualType.definition)!;
  final selection = skir.TypeSelection.wrapComplete(named.actualType);
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
  skir.TypeSelection selection,
  skir.RepresentationTemplate representation,
  skir.DataValue value,
  int depth,
) {
  if (depth > _maximumPortableValueDepth || value == skir.DataValue.unknown) {
    return false;
  }
  if (value == skir.DataValue.unfilled) return true;
  return switch (representation) {
    skir.RepresentationTemplate_scalarWrapper(value: final scalar) =>
      admitsPortableScalarValue(scalar.kind, value),
    skir.RepresentationTemplate_recordWrapper() => _admitsRecord(
      catalog,
      selection,
      value,
      depth + 1,
    ),
    skir.RepresentationTemplate_sequenceWrapper(value: final sequence) =>
      _admitsSequence(catalog, selection, sequence, value, depth + 1),
    skir.RepresentationTemplate_mappingWrapper(value: final mapping) =>
      _admitsMapping(catalog, selection, mapping, value, depth + 1),
    skir.RepresentationTemplate_enumerationWrapper(value: final enumeration) =>
      value is skir.DataValue_enumCaseWrapper &&
          enumeration.cases.any((candidate) => candidate.key == value.value),
    skir.RepresentationTemplate_linkWrapper(value: final link) =>
      value is skir.DataValue_linkWrapper &&
          value.value.endpoint == link.endpoint,
    _ => false,
  };
}

bool _admitsRecord(
  CheckedEditorCatalog catalog,
  skir.TypeSelection selection,
  skir.DataValue value,
  int depth,
) {
  final record = switch (value) {
    skir.DataValue_recordWrapper(:final value) => value,
    _ => null,
  };
  if (record == null) return false;
  final fields = catalog.fields(selection);
  if (fields.any((field) => field.type == null)) return false;
  final expected = {
    for (final field in fields) field.template.key: field.type!,
  };
  final actual = <String, skir.DataValue>{};
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
  skir.TypeSelection selection,
  skir.SequenceRepresentationTemplate representation,
  skir.DataValue value,
  int depth,
) {
  final items = switch ((representation.kind, value)) {
    (final kind, skir.DataValue_listValueWrapper(value: final payload))
        when kind == skir.CollectionKind.list =>
      payload.items,
    (final kind, skir.DataValue_setValueWrapper(value: final payload))
        when kind == skir.CollectionKind.set_ =>
      payload.items,
    _ => null,
  };
  final itemType = catalog.applyTemplate(representation.item, selection);
  if (items == null || itemType == null) return false;
  final ids = <skir.ItemId>{};
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
  skir.TypeSelection selection,
  skir.MappingRepresentationTemplate representation,
  skir.DataValue value,
  int depth,
) {
  final rows = switch (value) {
    skir.DataValue_mapValueWrapper(:final value) => value.rows,
    _ => null,
  };
  final keyType = catalog.applyTemplate(representation.key, selection);
  final valueType = catalog.applyTemplate(representation.value, selection);
  if (rows == null || keyType == null || valueType == null) return false;
  final ids = <skir.ItemId>{};
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
