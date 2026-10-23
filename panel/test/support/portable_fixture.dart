/// Readers for the compact values and locations of the shared portable
/// fixtures under `skir-src/editor/v1/fixtures` (format in
/// `operations/README.md` there).
library;

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

/// Fails when [value] holds keys outside [allowed]; the fixtures reject
/// unknown keys on every host.
void expectFixtureKeys(
  Map<String, Object?> value,
  Set<String> allowed,
  String what,
) {
  expect(
    value.keys.toSet().difference(allowed),
    isEmpty,
    reason: "unknown $what keys",
  );
}

/// A compact fixture value as a data value.
skir.DataValue fixtureValue(Map<String, Object?> source) {
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
            value: fixtureValue(value! as Map<String, Object?>),
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
            key: fixtureValue(row["key"]! as Map<String, Object?>),
            value: fixtureValue(row["value"]! as Map<String, Object?>),
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
        payload: fixtureValue(named["payload"]! as Map<String, Object?>),
      );
    }(),
    _ => throw StateError("Unknown compact value kind $key"),
  };
}

List<skir.ListItem> _items(Object? items) => [
  for (final item in (items! as List<Object?>).cast<Map<String, Object?>>())
    skir.ListItem(
      id: skir.ItemId(value: item["id"]! as String),
      value: fixtureValue(item["value"]! as Map<String, Object?>),
    ),
];

/// A location in the fixture's compact form, such as `subject.tags[a]`.
String fixtureLocation(skir.ValueLocation location) => [
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
