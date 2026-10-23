import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/catalog_fixture.dart";
import "../../../support/portable_fixture.dart";

/// Runs every case of the shared operation fixture
/// (`skir-src/editor/v1/fixtures/operations/*.json`, format in the README
/// there). The panel runs every case, rule and panel profile alike, and
/// compares the outcome and the reads of each in order; `check` belongs to
/// the Kotlin checker and is ignored here.
void main() {
  final directory = Directory("../skir-src/editor/v1/fixtures/operations");
  final files =
      directory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith(".json"))
          .toList()
        ..sort((left, right) => left.path.compareTo(right.path));
  final ids = <String>{};
  for (final file in files) {
    final document =
        jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    group(file.uri.pathSegments.last, () {
      test("holds only cases", () => expect(document.keys, ["cases"]));
      for (final fixture
          in (document["cases"]! as List<Object?>)
              .cast<Map<String, Object?>>()) {
        final id = fixture["id"]! as String;
        final unique = ids.add(id);
        test(id, () {
          expect(unique, isTrue, reason: "case ids are unique across files");
          _runCase(fixture);
        });
      }
    });
  }
}

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

void _runCase(Map<String, Object?> fixture) {
  expectFixtureKeys(fixture, _caseKeys, "case");
  final expression = skir.ExpressionNode.serializer.fromJson(
    fixture["expression"],
  );
  _expectRoundTrips(expression);
  final catalog = testCheckedCatalog(
    types: [
      for (final encoded
          in fixture["typeDefinitions"] as List<Object?>? ?? const [])
        _published(skir.TypeDefinition.serializer.fromJson(encoded)),
    ],
  );
  final resources = fixture["resources"] as Map<String, Object?>?;
  final result = PortableExpressionEvaluator.located(
    _inputs(fixture["inputs"] as Map<String, Object?>? ?? const {}),
    budget: _budget(fixture["budget"] as Map<String, Object?>?),
    catalog: catalog,
    queries: PortableExpressionQueries(
      catalog: catalog,
      authored: _FixtureDocument(
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

skir.PublishedType _published(skir.TypeDefinition definition) =>
    skir.PublishedType(
      searchKey: null,
      placementField: null,
      definition: definition,
      status: skir.DeclarationStatus.ready,
      effectiveFields: [
        if (definition.representation
            case skir.RepresentationTemplate_recordWrapper(:final value))
          for (final field in value.fields)
            skir.EffectiveFieldTemplate(
              key: field.owner.name,
              owner: field.owner,
              type: field.type,
              rules: const [],
            ),
      ],
      ancestorTemplates: definition.parents,
      display: defaultTypeDisplay(""),
    );

/// The authored resources of one case.
final class _FixtureDocument implements PortableAuthoringView {
  _FixtureDocument(this.generation, this.resources);

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
      const PortablePathUnavailable("Expressions read resources directly");

  @override
  skir.DataValue defaultValue(skir.TypeUse? type) => skir.DataValue.unfilled;
}
