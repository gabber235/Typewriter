import "package:json_annotation/json_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class TypeExpressionJsonConverter
    extends JsonConverter<TypeExpression, Map<String, Object?>> {
  const TypeExpressionJsonConverter();

  @override
  TypeExpression fromJson(Map<String, Object?> json) {
    final kind = json["kind"];
    return switch (kind) {
      "any" => const AnyType(),
      "unit" => const UnitType(),
      "boolean" => const BooleanType(),
      "string" => StringType(
        minimumLength: json["minimumLength"] as int?,
        maximumLength: json["maximumLength"] as int?,
        patterns: json["patterns"].asStringList,
      ),
      "bytes" => BytesType(
        minimumLength: json["minimumLength"] as int?,
        maximumLength: json["maximumLength"] as int?,
      ),
      "integer" => IntegerType(
        width: IntegerWidth.values.byName(json["width"]! as String),
        minimum: json["minimum"].asBigIntOrNull,
        maximum: json["maximum"].asBigIntOrNull,
      ),
      "float" => FloatType(
        width: FloatWidth.values.byName(json["width"]! as String),
        minimum: (json["minimum"] as num?)?.toDouble(),
        maximum: (json["maximum"] as num?)?.toDouble(),
      ),
      "decimal" => DecimalType(
        minimum: json["minimum"] as String?,
        maximum: json["maximum"] as String?,
        scale: json["scale"] as int?,
      ),
      "timestamp" => TimestampType(
        minimum: json["minimum"].asDateOrNull,
        maximum: json["maximum"].asDateOrNull,
      ),
      "duration" => DurationType(
        minimum: json["minimum"].asDurationOrNull,
        maximum: json["maximum"].asDurationOrNull,
      ),
      "enum" => EnumType(
        valueType: fromJson(json["valueType"].asObjectMap),
        values: json["values"].asObjectMaps
            .map(const DataValueJsonConverter().fromJson)
            .toList(),
      ),
      "list" => ListType(
        element: fromJson(json["element"].asObjectMap),
        minimumLength: json["minimumLength"] as int?,
        maximumLength: json["maximumLength"] as int?,
        unique: json["unique"] as bool? ?? false,
      ),
      "map" => MapType(
        key: fromJson(json["key"].asObjectMap),
        value: fromJson(json["value"].asObjectMap),
        minimumLength: json["minimumLength"] as int?,
        maximumLength: json["maximumLength"] as int?,
      ),
      "record" => _record(json),
      "named" => NamedType(
        ResolvedTypeRef(
          id: json["id"].asObjectMap.decodeTypeId(),
          revision: json["revision"]! as int,
          arguments: json["arguments"].asObjectMaps.map(fromJson).toList(),
        ),
      ),
      "parameter" => ParameterType(json["name"]! as String),
      _ => throw FormatException("Unknown type expression kind '$kind'"),
    };
  }

  @override
  Map<String, Object?> toJson(TypeExpression type) => switch (type) {
    AnyType() => {"kind": "any"},
    UnitType() => {"kind": "unit"},
    BooleanType() => {"kind": "boolean"},
    StringType() => {
      "kind": "string",
      "minimumLength": type.minimumLength,
      "maximumLength": type.maximumLength,
      "patterns": type.patterns,
    },
    BytesType() => {
      "kind": "bytes",
      "minimumLength": type.minimumLength,
      "maximumLength": type.maximumLength,
    },
    IntegerType() => {
      "kind": "integer",
      "width": type.width.name,
      "minimum": type.minimum?.toString(),
      "maximum": type.maximum?.toString(),
    },
    FloatType() => {
      "kind": "float",
      "width": type.width.name,
      "minimum": type.minimum,
      "maximum": type.maximum,
    },
    DecimalType() => {
      "kind": "decimal",
      "minimum": type.minimum,
      "maximum": type.maximum,
      "scale": type.scale,
    },
    TimestampType() => {
      "kind": "timestamp",
      "minimum": type.minimum?.toIso8601String(),
      "maximum": type.maximum?.toIso8601String(),
    },
    DurationType() => {
      "kind": "duration",
      "minimum": type.minimum?.inMicroseconds,
      "maximum": type.maximum?.inMicroseconds,
    },
    EnumType() => {
      "kind": "enum",
      "valueType": toJson(type.valueType),
      "values": type.values.map(const DataValueJsonConverter().toJson).toList(),
    },
    ListType() => {
      "kind": "list",
      "element": toJson(type.element),
      "minimumLength": type.minimumLength,
      "maximumLength": type.maximumLength,
      "unique": type.unique,
    },
    MapType() => {
      "kind": "map",
      "key": toJson(type.key),
      "value": toJson(type.value),
      "minimumLength": type.minimumLength,
      "maximumLength": type.maximumLength,
    },
    RecordType() => {
      "kind": "record",
      "closed": type.closed,
      "fields": {
        for (final field in type.fields.values)
          field.name: {
            "type": toJson(field.type),
            if (field.initialValue != null)
              "initialValue": const DataValueJsonConverter().toJson(
                field.initialValue!,
              ),
          },
      },
    },
    NamedType() => {
      "kind": "named",
      "id": type.reference.id.encodeTypeId(),
      "revision": type.reference.revision,
      "arguments": type.reference.arguments.map(toJson).toList(),
    },
    ParameterType() => {"kind": "parameter", "name": type.name},
  };

  RecordType _record(Map<String, Object?> json) {
    final fields = <String, TypeField>{};
    for (final entry in json["fields"].asObjectMap.entries) {
      final field = entry.value.asObjectMap;
      fields[entry.key] = TypeField(
        name: entry.key,
        type: fromJson(field["type"].asObjectMap),
        initialValue: field["initialValue"] == null
            ? null
            : const DataValueJsonConverter().fromJson(
                field["initialValue"].asObjectMap,
              ),
      );
    }
    return RecordType(fields: fields, closed: json["closed"] as bool? ?? true);
  }
}

extension on Map<String, Object?> {
  TypeId decodeTypeId() => switch (this["kind"]) {
    "builtin" => switch (this["name"]) {
      "option" => const TypeId.option(),
      "some" => const TypeId.some(),
      "none" => const TypeId.none(),
      _ => throw const FormatException("Unknown builtin type ID"),
    },
    "qualified" => QualifiedTypeId(
      namespace: this["namespace"]! as String,
      name: this["name"]! as String,
    ),
    final kind => throw FormatException("Unknown type identity kind '$kind'"),
  };
}

extension on TypeId {
  Map<String, Object?> encodeTypeId() => switch (this) {
    OptionTypeId() => {"kind": "builtin", "name": "option"},
    SomeTypeId() => {"kind": "builtin", "name": "some"},
    NoneTypeId() => {"kind": "builtin", "name": "none"},
    QualifiedTypeId(:final namespace, :final name) => {
      "kind": "qualified",
      "namespace": namespace,
      "name": name,
    },
  };
}

extension on Object? {
  Map<String, Object?> get asObjectMap =>
      (this! as Map).cast<String, Object?>();

  List<Map<String, Object?>> get asObjectMaps => (this as List? ?? const [])
      .map<Map<String, Object?>>((value) => (value as Object?).asObjectMap)
      .toList();

  List<String> get asStringList => (this as List? ?? const []).cast<String>();

  BigInt? get asBigIntOrNull => this == null ? null : BigInt.parse(toString());

  DateTime? get asDateOrNull =>
      this == null ? null : DateTime.parse(this! as String);

  Duration? get asDurationOrNull =>
      this == null ? null : Duration(microseconds: (this! as num).toInt());
}
