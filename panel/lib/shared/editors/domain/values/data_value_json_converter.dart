import "dart:typed_data";

import "package:json_annotation/json_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class DataValueJsonConverter
    extends JsonConverter<DataValue, Map<String, Object?>> {
  const DataValueJsonConverter();

  @override
  DataValue fromJson(Map<String, Object?> json) => switch (json["kind"]) {
    "unit" => const UnitValue(),
    "boolean" => BooleanValue(json.requiredValue<bool>("value")),
    "integer" => IntegerValue(
      BigInt.parse(json.requiredValue<String>("value")),
    ),
    "float" => FloatValue(json.requiredValue<num>("value").toDouble()),
    "decimal" => DecimalValue(json.requiredValue<String>("value")),
    "string" => StringValue(json.requiredValue<String>("value")),
    "bytes" => BytesValue(
      Uint8List.fromList(json.requiredValue<List>("value").cast<int>()),
    ),
    "timestamp" => TimestampValue(
      DateTime.parse(json.requiredValue<String>("value")),
    ),
    "duration" => DurationValue(
      Duration(microseconds: json.requiredValue<int>("value")),
    ),
    "list" => ListValue(json.requiredMaps("values").map(fromJson).toList()),
    "map" => MapValue(
      json
          .requiredMaps("entries")
          .map(
            (entry) => DataMapEntry(
              key: fromJson(entry.requiredMap("key")),
              value: fromJson(entry.requiredMap("value")),
            ),
          )
          .toList(),
    ),
    "record" => RecordValue({
      for (final entry in json.requiredValue<Map>("fields").entries)
        entry.key as String: fromJson(
          (entry.value as Map).cast<String, Object?>(),
        ),
    }),
    "polymorphic" => PolymorphicValue(
      concreteType: _decodeReference(json.requiredMap("type")),
      value: fromJson(json.requiredMap("value")),
    ),
    final kind => throw FormatException("Unknown data value kind '$kind'"),
  };

  @override
  Map<String, Object?> toJson(DataValue value) => switch (value) {
    UnitValue() => {"kind": "unit"},
    BooleanValue(:final value) => {"kind": "boolean", "value": value},
    IntegerValue(:final value) => {"kind": "integer", "value": "$value"},
    FloatValue(:final value) => {"kind": "float", "value": value},
    DecimalValue(:final value) => {"kind": "decimal", "value": value},
    StringValue(:final value) => {"kind": "string", "value": value},
    BytesValue(:final value) => {"kind": "bytes", "value": value.toList()},
    TimestampValue(:final value) => {
      "kind": "timestamp",
      "value": value.toIso8601String(),
    },
    DurationValue(:final value) => {
      "kind": "duration",
      "value": value.inMicroseconds,
    },
    ListValue(:final values) => {
      "kind": "list",
      "values": values.map(toJson).toList(),
    },
    MapValue(:final entries) => {
      "kind": "map",
      "entries": [
        for (final entry in entries)
          {"key": toJson(entry.key), "value": toJson(entry.value)},
      ],
    },
    RecordValue(:final fields) => {
      "kind": "record",
      "fields": {
        for (final entry in fields.entries) entry.key: toJson(entry.value),
      },
    },
    PolymorphicValue(:final concreteType, :final value) => {
      "kind": "polymorphic",
      "type": _encodeReference(concreteType),
      "value": toJson(value),
    },
  };

  ResolvedTypeRef _decodeReference(Map<String, Object?> json) =>
      ResolvedTypeRef(
        id: _decodeTypeId(json.requiredMap("id")),
        revision: json.requiredValue<int>("revision"),
        arguments: json
            .requiredMaps("arguments")
            .map(const TypeExpressionJsonConverter().fromJson)
            .toList(),
      );

  Map<String, Object?> _encodeReference(ResolvedTypeRef reference) => {
    "id": _encodeTypeId(reference.id),
    "revision": reference.revision,
    "arguments": reference.arguments
        .map(const TypeExpressionJsonConverter().toJson)
        .toList(),
  };

  TypeId _decodeTypeId(Map<String, Object?> json) => switch (json["kind"]) {
    "builtin" => switch (json.requiredValue<String>("name")) {
      "option" => const TypeId.option(),
      "some" => const TypeId.some(),
      "none" => const TypeId.none(),
      _ => throw const FormatException("Unknown builtin type ID"),
    },
    "qualified" => QualifiedTypeId(
      namespace: json.requiredValue<String>("namespace"),
      name: json.requiredValue<String>("name"),
    ),
    final kind => throw FormatException("Unknown type identity kind '$kind'"),
  };

  Map<String, Object?> _encodeTypeId(TypeId id) => switch (id) {
    OptionTypeId() => {"kind": "builtin", "name": "option"},
    SomeTypeId() => {"kind": "builtin", "name": "some"},
    NoneTypeId() => {"kind": "builtin", "name": "none"},
    QualifiedTypeId() => {
      "kind": "qualified",
      "namespace": id.namespace,
      "name": id.name,
    },
  };
}

class RecordValueJsonConverter
    extends JsonConverter<RecordValue, Map<String, Object?>> {
  const RecordValueJsonConverter();

  @override
  RecordValue fromJson(Map<String, Object?> json) {
    final value = const DataValueJsonConverter().fromJson(json);
    if (value is! RecordValue) {
      throw const FormatException("Expected a tagged record value");
    }
    return value;
  }

  @override
  Map<String, Object?> toJson(RecordValue value) =>
      const DataValueJsonConverter().toJson(value);
}

extension on Map<String, Object?> {
  T requiredValue<T>(String key) {
    final value = this[key];
    if (value is! T) {
      throw FormatException("Data value field '$key' must be $T");
    }
    return value;
  }

  Map<String, Object?> requiredMap(String key) =>
      requiredValue<Map>(key).cast<String, Object?>();

  List<Map<String, Object?>> requiredMaps(String key) => requiredValue<List>(
    key,
  ).map((value) => (value as Map).cast<String, Object?>()).toList();
}
