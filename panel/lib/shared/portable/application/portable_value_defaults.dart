import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The values a new field, item or row starts with when nothing prepares
/// them: false, empty text, zero, an empty collection or an enum's first
/// case, and unfilled where no value is plain enough to assume.
extension PortableValueDefaults on CheckedEditorCatalog {
  /// The value a new value of [type] starts with. A nullable starts empty
  /// and a record unfilled, since preparing one may need the backend.
  skir.DataValue defaultValue(skir.TypeUse? type) => switch (type) {
    skir.TypeUse_nullableWrapper() => skir.DataValue.null_,
    skir.TypeUse_scalarWrapper(:final value) => _scalarDefault(value),
    skir.TypeUse_namedWrapper(:final value) => _namedDefault(value),
    _ => skir.DataValue.unfilled,
  };

  /// A new value of the concrete record [type] made here: each field holds
  /// its [defaultValue], or a new record of its own where it is a concrete
  /// record. Constructor defaults the backend would evaluate are not applied.
  /// Null when [type] is not a concrete record.
  skir.DataValue? localRecord(skir.NamedTypeUse type) =>
      _localRecord(type, const {});

  skir.DataValue? _localRecord(
    skir.NamedTypeUse type,
    Set<skir.TypeDefinitionId> enclosing,
  ) {
    final published = this.published(type.definition);
    final representation = published?.definition.representation;
    if (published == null ||
        representation is! skir.RepresentationTemplate_recordWrapper ||
        !representation.isInstantiable ||
        enumCases(type.definition) != null ||
        enclosing.contains(type.definition)) {
      return null;
    }
    final selection = skir.TypeSelection.wrapComplete(type);
    final inside = {...enclosing, type.definition};
    return skir.DataValue.createNamed(
      actualType: type,
      payload: skir.DataValue.createRecord(
        fields: [
          for (final field in fields(selection))
            skir.FieldValue(
              name: field.template.key,
              value: switch (field.type) {
                skir.TypeUse_namedWrapper(:final value) =>
                  _localRecord(value, inside) ?? _namedDefault(value),
                final use => defaultValue(use),
              },
            ),
        ],
      ),
    );
  }

  skir.DataValue _namedDefault(skir.NamedTypeUse actual) {
    final published = this.published(actual.definition);
    if (published == null) return skir.DataValue.unfilled;
    final cases = enumCases(actual.definition);
    if (cases != null) {
      return skir.DataValue.createNamed(
        actualType: actual.member(cases.first),
        payload: skir.DataValue.unit,
      );
    }
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
      skir.RepresentationTemplate_linkWrapper() => skir.DataValue.unfilled,
      skir.RepresentationTemplate_recordWrapper() => skir.DataValue.unfilled,
      skir.RepresentationTemplate_unknown() => skir.DataValue.unfilled,
    };
    if (payload == skir.DataValue.unfilled) return payload;
    return skir.DataValue.createNamed(actualType: actual, payload: payload);
  }

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
