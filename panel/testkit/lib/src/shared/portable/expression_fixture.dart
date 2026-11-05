import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/authoring/document_builder.dart";
import "package:typewriter_testkit/src/shared/editors/catalog_fixture.dart";
import "package:typewriter_testkit/src/shared/portable/authored_records.dart";
import "package:typewriter_testkit/src/support/portable_fixture.dart";

const _caseKeys = {
  "id",
  "expression",
  "inputs",
  "check",
  "typeDefinitions",
  "resources",
  "budget",
  "expected",
};

/// Evaluates one case of the shared operation fixture format
/// (`skir-src/editor/v1/fixtures/operations/README.md`) in the panel and
/// expects the outcome and reads the case states. `check` belongs to the
/// Kotlin checker and is ignored here.
void runExpressionFixtureCase(Map<String, Object?> fixture) {
  expectFixtureKeys(fixture, _caseKeys, "case");
  final expression = skir.ExpressionNode.serializer.fromJson(
    fixture["expression"],
  );
  _expectRoundTrips(expression);
  final catalog = testCheckedCatalog(
    types: [
      for (final encoded
          in fixture["typeDefinitions"] as List<Object?>? ?? const [])
        declaredDefinition(skir.TypeDefinition.serializer.fromJson(encoded)),
    ],
  );
  final resources = fixture["resources"] as Map<String, Object?>?;
  final result = PortableExpressionEvaluator.located(
    _inputs(fixture["inputs"] as Map<String, Object?>? ?? const {}),
    budget: _budget(fixture["budget"] as Map<String, Object?>?),
    catalog: catalog,
    queries: PortableExpressionQueries(
      catalog: catalog,
      authored: AuthoredRecords(
        catalog.snapshot.generation,
        _records(resources ?? const {}),
      ),
    ),
  ).evaluate(expression);
  _expectOutcome(result, fixture["expected"]! as Map<String, Object?>);
}

/// The expression survives readable JSON, dense JSON and binary encoding.
/// Encodings compare as readable JSON, so a NaN literal round trips too.
void _expectRoundTrips(skir.ExpressionNode expression) {
  final serializer = skir.ExpressionNode.serializer;
  String readable(skir.ExpressionNode node) =>
      serializer.toJsonCode(node, readableFlavor: true);
  final expected = readable(expression);
  expect(
    readable(serializer.fromJsonCode(expected)),
    expected,
    reason: "readable JSON round trip",
  );
  expect(
    readable(serializer.fromJsonCode(serializer.toJsonCode(expression))),
    expected,
    reason: "dense JSON round trip",
  );
  expect(
    readable(serializer.fromBytes(serializer.toBytes(expression))),
    expected,
    reason: "binary round trip",
  );
}

skir.EvaluationBudget _budget(Map<String, Object?>? budget) {
  expectFixtureKeys(budget ?? const {}, {
    "maxSteps",
    "maxCollectionItems",
  }, "budget");
  return skir.EvaluationBudget(
    maxSteps: budget?["maxSteps"] as int? ?? 1000,
    maxCollectionItems: budget?["maxCollectionItems"] as int? ?? 1000,
  );
}

/// Bindings located like Kotlin: a located binding sits at the root of a
/// resource named after the binding.
Map<skir.ExpressionBindingId, PortableExpressionBinding> _inputs(
  Map<String, Object?> inputs,
) => {
  for (final MapEntry(:key, :value) in inputs.entries)
    skir.ExpressionBindingId(value: key): () {
      final input = value! as Map<String, Object?>;
      expectFixtureKeys(input, {"value", "type", "located"}, "input");
      return PortableExpressionBinding(
        value: fixtureValue(input["value"]! as Map<String, Object?>),
        location: input["located"] as bool? ?? true
            ? skir.ValueLocation(
                resource: skir.ResourceId(value: key),
                path: editorRootPath,
              )
            : null,
      );
    }(),
};

Map<skir.ResourceId, skir.AuthoringRecord> _records(
  Map<String, Object?> resources,
) => {
  for (final MapEntry(:key, :value) in resources.entries)
    skir.ResourceId(value: key): () {
      final resource = value! as Map<String, Object?>;
      expectFixtureKeys(resource, {"configuration", "fields"}, "resource");
      final fields = resource["fields"]! as Map<String, Object?>;
      return skir.AuthoringRecord(
        configuration: skir.TypeSelection.serializer.fromJson(
          resource["configuration"],
        ),
        fields: [
          for (final name in fields.keys.toList()..sort())
            skir.FieldValue(
              name: name,
              value: fixtureValue(fields[name]! as Map<String, Object?>),
            ),
        ],
      );
    }(),
};

void _expectOutcome(
  PortableExpressionResult result,
  Map<String, Object?> expected,
) {
  expectFixtureKeys(expected, {
    "available",
    "unavailable",
    "failed",
    "reads",
  }, "expected");
  expect(expected, contains("reads"), reason: "every case states its reads");
  final outcomes = expected.keys.where((key) => key != "reads");
  expect(outcomes, hasLength(1), reason: "one expected outcome");
  final description = _describe(result);
  switch (outcomes.single) {
    case "available":
      expect(result, isA<PortableExpressionAvailable>(), reason: description);
      expect(
        _compact((result as PortableExpressionAvailable).value),
        _compact(fixtureValue(expected["available"]! as Map<String, Object?>)),
      );
    case "unavailable":
      expect(result, isA<PortableExpressionUnavailable>(), reason: description);
      expect(
        (result as PortableExpressionUnavailable).locations.map(
          fixtureLocation,
        ),
        expected["unavailable"],
      );
    case "failed":
      expect(result, isA<PortableExpressionFailed>(), reason: description);
      expect(
        (result as PortableExpressionFailed).failure.value,
        expected["failed"],
      );
  }
  expect(result.reads.map(fixtureLocation), expected["reads"], reason: "reads");
}

String _describe(PortableExpressionResult result) => switch (result) {
  PortableExpressionAvailable(:final value) =>
    "available ${jsonEncode(_compact(value))}",
  PortableExpressionUnavailable(:final locations) =>
    "unavailable ${locations.map(fixtureLocation).toList()}",
  PortableExpressionFailed(:final failure, :final message) =>
    "failed ${failure.value}: $message",
};

/// A data value in the fixture's compact form: records compare as maps, and
/// collections compare in order with their item ids.
Object? _compact(skir.DataValue value) {
  if (value == skir.DataValue.null_) return {"null": true};
  if (value == skir.DataValue.unfilled) return {"unfilled": true};
  if (value == skir.DataValue.unit) return {"unit": true};
  return switch (value) {
    skir.DataValue_booleanWrapper(:final value) => {"boolean": value},
    skir.DataValue_integerWrapper(:final value) => {"integer": value},
    skir.DataValue_floatWrapper(:final value) => {"float": value},
    skir.DataValue_decimalWrapper(:final value) => {"decimal": value},
    skir.DataValue_stringValueWrapper(:final value) => {"string": value},
    skir.DataValue_bytesWrapper(:final value) => {"bytes": value.toBase64()},
    skir.DataValue_timestampWrapper(:final value) => {
      "timestamp": value.toUtc().toIso8601String(),
    },
    skir.DataValue_durationWrapper(:final value) => {
      "duration": "${value.value.milliseconds}",
    },
    skir.DataValue_enumCaseWrapper(:final value) => {"enum_case": value},
    skir.DataValue_recordWrapper(:final value) => {
      "record": {
        for (final field in value.fields) field.name: _compact(field.value),
      },
    },
    skir.DataValue_listValueWrapper(:final value) => {
      "list": [
        for (final item in value.items)
          {"id": item.id.value, "value": _compact(item.value)},
      ],
    },
    skir.DataValue_setValueWrapper(:final value) => {
      "set": [
        for (final item in value.items)
          {"id": item.id.value, "value": _compact(item.value)},
      ],
    },
    skir.DataValue_mapValueWrapper(:final value) => {
      "map": [
        for (final row in value.rows)
          {
            "id": row.id.value,
            "key": _compact(row.key),
            "value": _compact(row.value),
          },
      ],
    },
    skir.DataValue_linkWrapper(:final value) => {
      "link": {
        "endpoint": value.endpoint.value,
        "resource": value.target.resource.value,
      },
    },
    skir.DataValue_namedWrapper(:final value) => {
      "named": {
        "type": skir.NamedTypeUse.serializer.toJson(value.actualType),
        "payload": _compact(value.payload),
      },
    },
    _ => throw StateError("Unknown value $value"),
  };
}
