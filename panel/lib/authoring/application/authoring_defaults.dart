part of "realm_edit_model.dart";

final class _AuthoringDefaults {
  const _AuthoringDefaults(this.catalog);
  final CheckedEditorCatalog? catalog;
  skir.DataValue _defaultForNamed(skir.NamedTypeUse actual) {
    final checked = catalog;
    if (checked == null) return skir.DataValue.unfilled;
    final published = checked.published(actual.definition);
    if (published == null) return skir.DataValue.unfilled;
    final payload = switch (published.definition.representation) {
      skir.RepresentationTemplate_scalarWrapper(:final value) => _scalarDefault(
        value.kind,
      ),
      skir.RepresentationTemplate_sequenceWrapper(:final value) =>
        value.kind == skir.CollectionKind.list
            ? skir.DataValue.createListValue(items: const [])
            : skir.DataValue.createSetValue(items: const []),
      skir.RepresentationTemplate_mappingWrapper() =>
        skir.DataValue.createMapValue(rows: const []),
      skir.RepresentationTemplate_enumerationWrapper(:final value) =>
        value.cases.firstOrNull == null
            ? skir.DataValue.unfilled
            : skir.DataValue.wrapEnumCase(value.cases.first.key),
      skir.RepresentationTemplate_linkWrapper() => skir.DataValue.unfilled,
      skir.RepresentationTemplate_recordWrapper() => skir.DataValue.unfilled,
      skir.RepresentationTemplate_unknown() => skir.DataValue.unfilled,
    };
    if (payload == skir.DataValue.unfilled) return payload;
    return skir.DataValue.createNamed(actualType: actual, payload: payload);
  }

  skir.DataValue forType(skir.TypeUse? type) => switch (type) {
    skir.TypeUse_nullableWrapper() => skir.DataValue.null_,
    skir.TypeUse_scalarWrapper(:final value) => _scalarDefault(value),
    skir.TypeUse_namedWrapper(:final value) => _defaultForNamed(value),
    _ => skir.DataValue.unfilled,
  };

  skir.DataValue _scalarDefault(skir.ScalarKind kind) => switch (kind) {
    skir.ScalarKind.unit => skir.DataValue.unit,
    skir.ScalarKind.boolean => skir.DataValue.wrapBoolean(false),
    skir.ScalarKind.text => skir.DataValue.wrapStringValue(""),
    skir.ScalarKind_integerWrapper() => skir.DataValue.wrapInteger("0"),
    skir.ScalarKind_floatWrapper() => skir.DataValue.wrapFloat(0),
    skir.ScalarKind.decimal => skir.DataValue.wrapDecimal("0"),
    skir.ScalarKind.bytes => skir.DataValue.wrapBytes(skir.ByteString.empty),
    skir.ScalarKind.duration => skir.DataValue.createDuration(
      value: skir.Duration(milliseconds: 0),
    ),
    skir.ScalarKind.timestamp => skir.DataValue.unfilled,
    _ => skir.DataValue.unfilled,
  };
}
