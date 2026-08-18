import "dart:convert";
import "dart:typed_data";

import "package:json_annotation/json_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "data_value_json_cursor.dart";

class DataValueJsonConverter
    extends JsonConverter<DataValue, Map<String, Object?>> {
  const DataValueJsonConverter();

  @override
  DataValue fromJson(Map<String, Object?> json) =>
      _DataValueDecoder().decode(_JsonValue(json));

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

  Map<String, Object?> _encodeReference(ResolvedTypeRef reference) => {
    "id": _encodeTypeId(reference.id),
    "revision": reference.revision,
    "arguments": reference.arguments
        .map(const TypeExpressionJsonConverter().toJson)
        .toList(),
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

final class _DataValueDecoder {
  DataValue decode(_JsonValue json) {
    final kind = json.required("kind").string();
    return switch (kind) {
      "unit" => const UnitValue(),
      "boolean" => BooleanValue(json.required("value").boolean()),
      "integer" => IntegerValue(_decodeInteger(json.required("value"))),
      "float" => FloatValue(json.required("value").number().toDouble()),
      "decimal" => DecimalValue(json.required("value").string()),
      "string" => StringValue(json.required("value").string()),
      "bytes" => BytesValue(_decodeBytes(json.required("value"))),
      "timestamp" => TimestampValue(_decodeTimestamp(json.required("value"))),
      "duration" => DurationValue(
        Duration(microseconds: json.required("value").integer()),
      ),
      "list" => ListValue(_decodeValues(json.required("values"))),
      "map" => MapValue(_decodeEntries(json.required("entries"))),
      "record" => RecordValue(_decodeFields(json.required("fields"))),
      "polymorphic" => PolymorphicValue(
        concreteType: _decodeReference(json.required("type")),
        value: decode(json.required("value")),
      ),
      _ => throw FormatException(
        "Expected a known data value kind at ${json.required("kind").path}, "
        "got ${jsonEncode(kind)}",
      ),
    };
  }

  BigInt _decodeInteger(_JsonValue json) {
    final value = json.string();
    try {
      return BigInt.parse(value);
    } on FormatException {
      throw json.invalid("a decimal integer string");
    }
  }

  Uint8List _decodeBytes(_JsonValue json) {
    final values = json.list();
    final bytes = <int>[];
    for (final (index, value) in values.indexed) {
      final item = json.item(index, value);
      final byte = item.integer();
      if (byte < 0 || byte > 255) {
        throw item.invalid("an integer from 0 through 255");
      }
      bytes.add(byte);
    }
    return Uint8List.fromList(bytes);
  }

  DateTime _decodeTimestamp(_JsonValue json) {
    final value = json.string();
    try {
      return DateTime.parse(value);
    } on FormatException {
      throw json.invalid("an ISO 8601 timestamp string");
    }
  }

  List<DataValue> _decodeValues(_JsonValue json) {
    final values = json.list();
    return [
      for (final (index, value) in values.indexed)
        decode(json.item(index, value)),
    ];
  }

  List<DataMapEntry> _decodeEntries(_JsonValue json) {
    final entries = json.list();
    return [
      for (final (index, value) in entries.indexed)
        _decodeEntry(json.item(index, value)),
    ];
  }

  DataMapEntry _decodeEntry(_JsonValue json) => DataMapEntry(
    key: decode(json.required("key")),
    value: decode(json.required("value")),
  );

  Map<String, DataValue> _decodeFields(_JsonValue json) {
    final fields = json.object();
    return {
      for (final entry in fields.entries)
        entry.key: decode(json.property(entry.key, entry.value)),
    };
  }

  ResolvedTypeRef _decodeReference(_JsonValue json) => ResolvedTypeRef(
    id: _decodeTypeId(json.required("id")),
    revision: json.required("revision").integer(),
    arguments: _decodeTypeArguments(json.required("arguments")),
  );

  List<TypeExpression> _decodeTypeArguments(_JsonValue json) {
    final arguments = json.list();
    return [
      for (final (index, value) in arguments.indexed)
        _decodeTypeExpression(json.item(index, value)),
    ];
  }

  TypeExpression _decodeTypeExpression(_JsonValue json) {
    final value = json.object();
    try {
      return const TypeExpressionJsonConverter().fromJson(value);
    } on Object catch (error) {
      throw FormatException(
        "Expected a valid type expression object at ${json.path}, got $error",
      );
    }
  }

  TypeId _decodeTypeId(_JsonValue json) {
    final kind = json.required("kind").string();
    return switch (kind) {
      "builtin" => _decodeBuiltinTypeId(json.required("name")),
      "qualified" => QualifiedTypeId(
        namespace: json.required("namespace").string(),
        name: json.required("name").string(),
      ),
      _ => throw FormatException(
        "Expected a known type identity kind at ${json.required("kind").path}, "
        "got ${jsonEncode(kind)}",
      ),
    };
  }

  TypeId _decodeBuiltinTypeId(_JsonValue json) => switch (json.string()) {
    "option" => const TypeId.option(),
    "some" => const TypeId.some(),
    "none" => const TypeId.none(),
    final name => throw FormatException(
      "Expected a known builtin type ID at ${json.path}, got "
      "${jsonEncode(name)}",
    ),
  };
}

class RecordValueJsonConverter
    extends JsonConverter<RecordValue, Map<String, Object?>> {
  const RecordValueJsonConverter();

  @override
  RecordValue fromJson(Map<String, Object?> json) {
    final value = const DataValueJsonConverter().fromJson(json);
    if (value is! RecordValue) {
      throw FormatException(
        "Expected a tagged record value at \$, got ${value.runtimeType}",
      );
    }
    return value;
  }

  @override
  Map<String, Object?> toJson(RecordValue value) =>
      const DataValueJsonConverter().toJson(value);
}
