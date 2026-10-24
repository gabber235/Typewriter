import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Decodes external JSON against a complete checked authored type.
/// Named representations retain their type wrapper; records reject unknown
/// fields and require every nonnullable field. Invalid values fail with their
/// source path so the HTTP leaf can skip one bad row without losing other rows.
skir.DataValue decodePortableJson(
  Object? source,
  skir.TypeUse expected,
  CheckedEditorCatalog catalog,
  String path,
) {
  if (expected case skir.TypeUse_nullableWrapper(:final value)) {
    if (source == null) return skir.DataValue.null_;
    return decodePortableJson(source, value.value, catalog, path);
  }
  return switch (expected) {
    skir.TypeUse_scalarWrapper(:final value) => _decodePortableJsonScalar(
      source,
      value,
      path,
    ),
    skir.TypeUse_namedWrapper(:final value) => _decodePortableJsonNamed(
      source,
      value,
      catalog,
      path,
    ),
    _ => throw FormatException("Expected a complete authored type at $path"),
  };
}

skir.DataValue _decodePortableJsonNamed(
  Object? source,
  skir.NamedTypeUse expected,
  CheckedEditorCatalog catalog,
  String path,
) {
  final published = catalog.published(expected.definition);
  if (published == null || published.status != skir.DeclarationStatus.ready) {
    throw FormatException("Expected an available named type at $path");
  }
  final containing = skir.TypeSelection.wrapComplete(expected);
  final payload = switch (published.definition.representation) {
    skir.RepresentationTemplate_scalarWrapper(:final value) =>
      _decodePortableJsonScalar(source, value.kind, path),
    skir.RepresentationTemplate_recordWrapper() => _decodePortableJsonRecord(
      source,
      containing,
      catalog,
      path,
    ),
    skir.RepresentationTemplate_sequenceWrapper(:final value) =>
      _decodePortableJsonSequence(source, value, containing, catalog, path),
    skir.RepresentationTemplate_mappingWrapper(:final value) =>
      _decodePortableJsonMapping(source, value, containing, catalog, path),
    skir.RepresentationTemplate_enumerationWrapper(:final value) =>
      _decodePortableJsonEnumeration(source, value, path),
    skir.RepresentationTemplate_linkWrapper(:final value) =>
      _decodePortableJsonLink(source, value, path),
    _ => throw FormatException("Expected a supported named type at $path"),
  };
  return skir.DataValue.createNamed(actualType: expected, payload: payload);
}

skir.DataValue _decodePortableJsonScalar(
  Object? source,
  skir.ScalarKind kind,
  String path,
) {
  if (kind == skir.ScalarKind.unit && source == null) {
    return skir.DataValue.unit;
  }
  if (kind == skir.ScalarKind.boolean && source is bool) {
    return skir.DataValue.wrapBoolean(source);
  }
  if (kind == skir.ScalarKind.text && source is String) {
    return skir.DataValue.wrapStringValue(source);
  }
  if (kind == skir.ScalarKind.bytes && source is String) {
    try {
      return skir.DataValue.wrapBytes(
        skir.ByteString.copy(base64Decode(source)),
      );
    } on FormatException {
      throw _invalidPortableJson(path, "a valid base64 string", source);
    }
  }
  if (kind case skir.ScalarKind_integerWrapper()) {
    if (source is int || source is String) {
      final value = admitPortableNumericInput(
        current: null,
        expected: skir.TypeUse.wrapScalar(kind),
        text: source.toString(),
      );
      if (value != null) return value;
    }
    throw _invalidPortableJson(path, "an integer in range", source);
  }
  if (kind case skir.ScalarKind_floatWrapper()) {
    if (source is num) {
      final value = admitPortableNumericInput(
        current: null,
        expected: skir.TypeUse.wrapScalar(kind),
        text: source.toString(),
      );
      if (value != null) return value;
    }
    throw _invalidPortableJson(path, "a finite number in range", source);
  }
  if (kind == skir.ScalarKind.decimal && (source is num || source is String)) {
    final value = admitPortableNumericInput(
      current: null,
      expected: skir.TypeUse.wrapScalar(kind),
      text: source.toString(),
    );
    if (value != null) return value;
  }
  if (kind == skir.ScalarKind.timestamp && source is String) {
    final value = DateTime.tryParse(source);
    if (value != null) return skir.DataValue.wrapTimestamp(value);
  }
  if (kind == skir.ScalarKind.duration && source is int) {
    return skir.DataValue.createDuration(
      value: skir.Duration(milliseconds: source),
    );
  }
  throw _invalidPortableJson(path, "a ${kind.runtimeType} value", source);
}

skir.DataValue _decodePortableJsonRecord(
  Object? source,
  skir.TypeSelection containing,
  CheckedEditorCatalog catalog,
  String path,
) {
  if (source is! Map<String, Object?>) {
    throw _invalidPortableJson(path, "an object", source);
  }
  final fields = catalog.fields(containing);
  final declared = fields.map((field) => field.template.key).toSet();
  final unknown = source.keys
      .where((key) => !declared.contains(key))
      .firstOrNull;
  if (unknown != null) {
    throw FormatException("Expected a declared field at $path.$unknown");
  }
  return skir.DataValue.createRecord(
    fields: [
      for (final field in fields)
        skir.FieldValue(
          name: field.template.key,
          value: _decodePortableJsonField(
            source,
            field,
            catalog,
            "$path.${field.template.key}",
          ),
        ),
    ],
  );
}

skir.DataValue _decodePortableJsonField(
  Map<String, Object?> source,
  AppliedEditorField field,
  CheckedEditorCatalog catalog,
  String path,
) {
  final type = field.type;
  if (type == null) {
    throw FormatException("Expected an available field type at $path");
  }
  if (!source.containsKey(field.template.key)) {
    if (type is skir.TypeUse_nullableWrapper) return skir.DataValue.null_;
    throw FormatException("Expected a required field at $path");
  }
  return decodePortableJson(source[field.template.key], type, catalog, path);
}

skir.DataValue _decodePortableJsonSequence(
  Object? source,
  skir.SequenceRepresentationTemplate representation,
  skir.TypeSelection containing,
  CheckedEditorCatalog catalog,
  String path,
) {
  if (source is! List<Object?>) {
    throw _invalidPortableJson(path, "a list", source);
  }
  final itemType = catalog.applyTemplate(representation.item, containing);
  if (itemType == null) {
    throw FormatException("Expected a complete item type at $path");
  }
  final items = [
    for (final (index, item) in source.indexed)
      skir.ListItem(
        id: skir.ItemId(value: "http:$path:item:$index"),
        value: decodePortableJson(item, itemType, catalog, "$path[$index]"),
      ),
  ];
  return representation.kind == skir.CollectionKind.list
      ? skir.DataValue.createListValue(items: items)
      : skir.DataValue.createSetValue(items: items);
}

skir.DataValue _decodePortableJsonMapping(
  Object? source,
  skir.MappingRepresentationTemplate representation,
  skir.TypeSelection containing,
  CheckedEditorCatalog catalog,
  String path,
) {
  if (source is! Map<String, Object?>) {
    throw _invalidPortableJson(path, "an object", source);
  }
  final keyType = catalog.applyTemplate(representation.key, containing);
  final valueType = catalog.applyTemplate(representation.value, containing);
  if (keyType == null || valueType == null) {
    throw FormatException("Expected complete map types at $path");
  }
  return skir.DataValue.createMapValue(
    rows: [
      for (final (index, entry) in source.entries.indexed)
        skir.MapRow(
          id: skir.ItemId(value: "http:$path:row:$index"),
          key: decodePortableJson(
            entry.key,
            keyType,
            catalog,
            "$path.keys[$index]",
          ),
          value: decodePortableJson(
            entry.value,
            valueType,
            catalog,
            "$path.${entry.key}",
          ),
        ),
    ],
  );
}

skir.DataValue _decodePortableJsonEnumeration(
  Object? source,
  skir.EnumerationRepresentationTemplate representation,
  String path,
) {
  if (source is String &&
      representation.cases.any((candidate) => candidate.key == source)) {
    return skir.DataValue.wrapEnumCase(source);
  }
  throw _invalidPortableJson(path, "a declared enum case", source);
}

skir.DataValue _decodePortableJsonLink(
  Object? source,
  skir.LinkRepresentationTemplate representation,
  String path,
) {
  if (source is! String || source.isEmpty) {
    throw _invalidPortableJson(path, "a resource id string", source);
  }
  return skir.DataValue.createLink(
    endpoint: representation.endpoint,
    target: skir.LinkTarget(
      resource: skir.ResourceId(value: source),
      opposite: null,
    ),
  );
}

FormatException _invalidPortableJson(
  String path,
  String expected,
  Object? actual,
) => FormatException(
  "Expected $expected at $path, got ${actual == null ? "null" : actual.runtimeType}",
);
