import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/catalog_fixture.dart";

/// Runs every case of the shared operation fixture
/// (`skir-src/editor/v1/fixtures/operations/*.json`, format in the README
/// there). The panel runs every case, rule and panel profile alike; `check`
/// belongs to the Kotlin checker and is ignored here.
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
  _expectKeys(fixture, _caseKeys, "case");
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

void _expectKeys(Map<String, Object?> value, Set<String> allowed, String what) {
  expect(
    value.keys.toSet().difference(allowed),
    isEmpty,
    reason: "unknown $what keys",
  );
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
  _expectKeys(budget ?? const {}, {"maxSteps", "maxCollectionItems"}, "budget");
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
      _expectKeys(input, {"value", "type", "located"}, "input");
      return PortableExpressionBinding(
        value: _value(input["value"]! as Map<String, Object?>),
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
      _expectKeys(resource, {"configuration", "fields"}, "resource");
      final fields = resource["fields"]! as Map<String, Object?>;
      return skir.AuthoringRecord(
        configuration: skir.TypeSelection.serializer.fromJson(
          resource["configuration"],
        ),
        fields: [
          for (final name in fields.keys.toList()..sort())
            skir.FieldValue(
              name: name,
              value: _value(fields[name]! as Map<String, Object?>),
            ),
        ],
      );
    }(),
};

void _expectOutcome(
  PortableExpressionResult result,
  Map<String, Object?> expected,
) {
  _expectKeys(expected, {
    "available",
    "unavailable",
    "failed",
    "reads",
  }, "expected");
  final outcomes = expected.keys.where((key) => key != "reads");
  expect(outcomes, hasLength(1), reason: "one expected outcome");
  final description = _describe(result);
  switch (outcomes.single) {
    case "available":
      expect(result, isA<PortableExpressionAvailable>(), reason: description);
      expect(
        _compact((result as PortableExpressionAvailable).value),
        _compact(_value(expected["available"]! as Map<String, Object?>)),
      );
    case "unavailable":
      expect(result, isA<PortableExpressionUnavailable>(), reason: description);
      expect(
        (result as PortableExpressionUnavailable).locations.map(_location),
        expected["unavailable"],
      );
    case "failed":
      expect(result, isA<PortableExpressionFailed>(), reason: description);
      expect(
        (result as PortableExpressionFailed).failure.value,
        expected["failed"],
      );
  }
  expect(result.reads.map(_location), expected["reads"], reason: "reads");
}

String _describe(PortableExpressionResult result) => switch (result) {
  PortableExpressionAvailable(:final value) =>
    "available ${jsonEncode(_compact(value))}",
  PortableExpressionUnavailable(:final locations) =>
    "unavailable ${locations.map(_location).toList()}",
  PortableExpressionFailed(:final failure, :final message) =>
    "failed ${failure.value}: $message",
};

/// A compact fixture value as a data value.
skir.DataValue _value(Map<String, Object?> source) {
  expect(source, hasLength(1), reason: "compact value $source");
  final MapEntry(:key, :value) = source.entries.single;
  return switch (key) {
    "null" => skir.DataValue.null_,
    "unfilled" => skir.DataValue.unfilled,
    "unit" => skir.DataValue.unit,
    "boolean" => skir.DataValue.wrapBoolean(value! as bool),
    "integer" => skir.DataValue.wrapInteger(value! as String),
    "float" => skir.DataValue.wrapFloat((value! as num).toDouble()),
    "decimal" => skir.DataValue.wrapDecimal(value! as String),
    "string" => skir.DataValue.wrapStringValue(value! as String),
    "bytes" => skir.DataValue.wrapBytes(
      skir.ByteString.fromBase64(value! as String),
    ),
    "timestamp" => skir.DataValue.wrapTimestamp(
      DateTime.parse(value! as String).toUtc(),
    ),
    "duration" => skir.DataValue.createDuration(
      value: skir.Duration(milliseconds: int.parse(value! as String)),
    ),
    "enum_case" => skir.DataValue.wrapEnumCase(value! as String),
    "record" => skir.DataValue.createRecord(
      fields: [
        for (final MapEntry(:key, :value)
            in (value! as Map<String, Object?>).entries)
          skir.FieldValue(
            name: key,
            value: _value(value! as Map<String, Object?>),
          ),
      ],
    ),
    "list" => skir.DataValue.createListValue(items: _items(value)),
    "set" => skir.DataValue.createSetValue(items: _items(value)),
    "map" => skir.DataValue.createMapValue(
      rows: [
        for (final row
            in (value! as List<Object?>).cast<Map<String, Object?>>())
          skir.MapRow(
            id: skir.ItemId(value: row["id"]! as String),
            key: _value(row["key"]! as Map<String, Object?>),
            value: _value(row["value"]! as Map<String, Object?>),
          ),
      ],
    ),
    "link" => () {
      final link = value! as Map<String, Object?>;
      return skir.DataValue.wrapLink(
        skir.LinkValue(
          endpoint: skir.EndpointId(value: link["endpoint"]! as String),
          target: skir.LinkTarget(
            resource: skir.ResourceId(value: link["resource"]! as String),
            opposite: null,
          ),
        ),
      );
    }(),
    "named" => () {
      final named = value! as Map<String, Object?>;
      final declared = named["declared"] as String?;
      return skir.DataValue.createNamed(
        actualType: skir.NamedTypeUse(
          definition: skir.TypeDefinitionId(
            typeId: declared != null
                ? skir.TypeId.wrapDeclared(skir.DeclaredTypeId(value: declared))
                : skir.TypeId.createQualified(
                    namespace: named["namespace"]! as String,
                    name: named["name"]! as String,
                  ),
            revision: named["revision"]! as int,
          ),
          arguments: [
            for (final argument
                in named["arguments"] as List<Object?>? ?? const [])
              skir.TypeUse.serializer.fromJson(argument),
          ],
        ),
        payload: _value(named["payload"]! as Map<String, Object?>),
      );
    }(),
    _ => throw StateError("Unknown compact value kind $key"),
  };
}

List<skir.ListItem> _items(Object? items) => [
  for (final item in (items! as List<Object?>).cast<Map<String, Object?>>())
    skir.ListItem(
      id: skir.ItemId(value: item["id"]! as String),
      value: _value(item["value"]! as Map<String, Object?>),
    ),
];

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

/// A location in the fixture's compact form, such as `subject.tags[a]`.
String _location(skir.ValueLocation location) => [
  location.resource.value,
  for (final segment in location.path.segments)
    if (segment == skir.PathSegment.mapKey)
      ".#key"
    else if (segment == skir.PathSegment.mapValue)
      ".#value"
    else
      switch (segment) {
        skir.PathSegment_fieldWrapper(:final value) => ".${value.name}",
        skir.PathSegment_itemWrapper(:final value) => "[${value.id.value}]",
        _ => throw StateError("Unknown path segment $segment"),
      },
].join();

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
