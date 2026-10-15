import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "portable_value_admission.freezed.dart";

@freezed
abstract class PortableValueInspection with _$PortableValueInspection {
  const factory PortableValueInspection({
    @Default([]) List<PortableValueProblem> structuralProblems,
    @Default([]) List<skir.ValuePath> unfinished,
  }) = _PortableValueInspection;
}

@freezed
abstract class PortableValueProblem with _$PortableValueProblem {
  const factory PortableValueProblem({
    required skir.ValuePath path,
    required String code,
  }) = _PortableValueProblem;
}

/// Applies the checked portable schema before a backend codec receives a write.
extension PortableValueAdmission on CheckedEditorCatalog {
  bool admitsPortableValue(skir.TypeUse expected, skir.DataValue value) =>
      inspectPortableValue(expected, value).structuralProblems.isEmpty;

  /// Draft admission accepts unfinished values; completeness retains their paths.
  PortableValueInspection inspectPortableValue(
    skir.TypeUse expected,
    skir.DataValue value,
  ) {
    final inspection = _PortableValueInspector(this)
      ..visit(expected, value, const [], 0);
    return PortableValueInspection(
      structuralProblems: inspection.problems,
      unfinished: inspection.unfinished,
    );
  }

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

/// One traversal owns structural admission and completeness locations.
final class _PortableValueInspector {
  _PortableValueInspector(this.catalog);
  final CheckedEditorCatalog catalog;
  final problems = <PortableValueProblem>[];
  final unfinished = <skir.ValuePath>[];

  void problem(List<skir.PathSegment> path, String code) => problems.add(
    PortableValueProblem(
      path: skir.ValuePath(segments: path),
      code: code,
    ),
  );

  bool stop(skir.DataValue value, List<skir.PathSegment> path, int depth) {
    if (depth > 512 || value == skir.DataValue.unknown) {
      problem(path, depth > 512 ? "value_depth_limit" : "unknown_value");
      return true;
    }
    if (value == skir.DataValue.unfilled) {
      unfinished.add(skir.ValuePath(segments: path));
      return true;
    }
    return false;
  }

  String scalarProblem(skir.ScalarKind kind, skir.DataValue value) {
    if (kind is skir.ScalarKind_floatWrapper &&
        kind.value.width == skir.FloatWidth.thirtyTwo &&
        value is skir.DataValue_floatWrapper &&
        value.value.isFinite &&
        Float32List.fromList([value.value]).single != value.value) {
      return "float32_precision_loss";
    }
    return "wrong_scalar";
  }

  void visit(
    skir.TypeUse expected,
    skir.DataValue value,
    List<skir.PathSegment> path,
    int depth,
  ) {
    if (stop(value, path, depth)) return;
    switch (expected) {
      case skir.TypeUse_nullableWrapper(value: final nullable):
        if (value != skir.DataValue.null_) {
          visit(nullable.value, value, path, depth + 1);
        }
      case skir.TypeUse_scalarWrapper(value: final scalar):
        if (!admitsPortableScalarValue(scalar, value)) {
          problem(path, scalarProblem(scalar, value));
        }
      case skir.TypeUse_namedWrapper(value: final expectedNamed):
        if (value is! skir.DataValue_namedWrapper) {
          problem(path, "expected_named");
          return;
        }
        final named = value.value;
        if (!catalog.isReadableAs(
          skir.TypeUse.wrapNamed(named.actualType),
          expected,
        )) {
          problem(path, "unreadable_actual_type");
          return;
        }
        if (!catalog.isReadyApplication(named.actualType) ||
            !catalog.isReadyApplication(expectedNamed)) {
          problem(path, "unavailable_type");
          return;
        }
        payload(
          skir.TypeSelection.wrapComplete(named.actualType),
          catalog
              .published(named.actualType.definition)!
              .definition
              .representation,
          named.payload,
          path,
          depth + 2,
        );
      default:
        problem(path, "unknown_type");
    }
  }

  void payload(
    skir.TypeSelection selection,
    skir.RepresentationTemplate representation,
    skir.DataValue value,
    List<skir.PathSegment> path,
    int depth,
  ) {
    if (stop(value, path, depth)) return;
    switch (representation) {
      case skir.RepresentationTemplate_scalarWrapper(value: final scalar):
        if (!admitsPortableScalarValue(scalar.kind, value)) {
          problem(path, scalarProblem(scalar.kind, value));
        }
      case skir.RepresentationTemplate_recordWrapper():
        if (value is! skir.DataValue_recordWrapper) {
          problem(path, "expected_record");
          return;
        }
        final fields = catalog.fields(selection);
        final expected = {
          for (final field in fields) field.template.key: field.type,
        };
        final actual = <String, skir.DataValue>{};
        for (final field in value.value.fields) {
          final at = [...path, skir.PathSegment.createField(name: field.name)];
          if (actual.containsKey(field.name)) problem(at, "duplicate_field");
          actual[field.name] = field.value;
          if (!expected.containsKey(field.name)) problem(at, "unknown_field");
        }
        for (final field in expected.entries) {
          final at = [...path, skir.PathSegment.createField(name: field.key)];
          final present = actual[field.key];
          if (present == null) {
            problem(at, "missing_field");
          } else if (field.value == null) {
            problem(at, "unavailable_type");
          } else {
            visit(field.value!, present, at, depth + 2);
          }
        }
      case skir.RepresentationTemplate_sequenceWrapper(value: final sequence):
        final items = switch ((sequence.kind, value)) {
          (final kind, skir.DataValue_listValueWrapper(value: final v))
              when kind == skir.CollectionKind.list =>
            v.items,
          (final kind, skir.DataValue_setValueWrapper(value: final v))
              when kind == skir.CollectionKind.set_ =>
            v.items,
          _ => null,
        };
        final itemType = catalog.applyTemplate(sequence.item, selection);
        if (items == null || itemType == null) {
          problem(
            path,
            items == null
                ? (sequence.kind == skir.CollectionKind.list
                      ? "expected_list"
                      : "expected_set")
                : "unavailable_type",
          );
          return;
        }
        final ids = <skir.ItemId>{};
        for (final item in items) {
          final at = [...path, skir.PathSegment.createItem(id: item.id)];
          if (!ids.add(item.id)) problem(at, "duplicate_item_id");
          visit(itemType, item.value, at, depth + 2);
        }
      case skir.RepresentationTemplate_mappingWrapper(value: final mapping):
        final keyType = catalog.applyTemplate(mapping.key, selection);
        final valueType = catalog.applyTemplate(mapping.value, selection);
        if (value is! skir.DataValue_mapValueWrapper ||
            keyType == null ||
            valueType == null) {
          problem(
            path,
            value is! skir.DataValue_mapValueWrapper
                ? "expected_map"
                : "unavailable_type",
          );
          return;
        }
        final ids = <skir.ItemId>{};
        for (final row in value.value.rows) {
          final at = [...path, skir.PathSegment.createItem(id: row.id)];
          if (!ids.add(row.id)) problem(at, "duplicate_item_id");
          visit(keyType, row.key, [...at, skir.PathSegment.mapKey], depth + 2);
          visit(valueType, row.value, [
            ...at,
            skir.PathSegment.mapValue,
          ], depth + 2);
        }
      case skir.RepresentationTemplate_enumerationWrapper(
        value: final enumeration,
      ):
        if (value is! skir.DataValue_enumCaseWrapper ||
            !enumeration.cases.any((c) => c.key == value.value)) {
          problem(
            path,
            value is skir.DataValue_enumCaseWrapper
                ? "unknown_enum_case"
                : "expected_enum",
          );
        }
      case skir.RepresentationTemplate_linkWrapper(value: final link):
        if (value is! skir.DataValue_linkWrapper ||
            value.value.endpoint != link.endpoint) {
          problem(
            path,
            value is skir.DataValue_linkWrapper
                ? "wrong_endpoint"
                : "expected_link",
          );
        }
      default:
        problem(path, "unknown_representation");
    }
  }
}
