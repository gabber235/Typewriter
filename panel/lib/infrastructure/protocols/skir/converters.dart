// Bridges panel primitives and shared Skir identity values.
//
// This boundary keeps Flutter representations and Surreal record syntax out
// of domain models. Resource identifiers are generated here so one identity
// can be reused across an authoring batch and any retry of that batch.
import "dart:math";

import "package:flutter/material.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

/// Converts the protocol color representation into Flutter's color value.
extension SkirColorExtension on skir.Color {
  Color toFlutterColor() {
    return Color(argb.toUnsigned(32));
  }
}

/// Converts a Flutter color into the signed ARGB value required by Skir.
extension FlutterColorToSkirExtension on Color {
  skir.Color toSkirColor() {
    return skir.Color(argb: toARGB32().toSigned(32));
  }
}

/// Exposes the route form and query literal form of a Skir record identity.
extension RecordIdExtension on skir.RecordId {
  /// The opaque string key used by routes and resource references.
  String get id => switch (key) {
    skir.RecordIdKey_stringWrapper(:final value) => value,
    _ => throw StateError("Expected a string record key for $table"),
  };

  /// Formats this identity for SurrealQL record references and queries.
  String toSurrealQl() =>
      "${_formatStringKey(table)}:${_formatRecordIdKey(key)}";
}

final _resourceRandom = Random.secure();
const _resourceAlphabet = "abcdefghijklmnopqrstuvwxyz0123456789";

/// Creates an identity for a new authoring resource.
///
/// Callers must retain the returned value for the complete submission flow.
/// Reusing it across retries makes a replay address the same resource instead
/// of creating a duplicate.
skir.ResourceId newResourceId() => skir.ResourceId(
  value: String.fromCharCodes([
    for (var index = 0; index < 20; index++)
      _resourceAlphabet.codeUnitAt(_resourceRandom.nextInt(36)),
  ]),
);

extension ResourceIdExtension on skir.ResourceId {
  String get id => value;
}

String _formatRecordIdKey(skir.RecordIdKey key) {
  return switch (key) {
    skir.RecordIdKey_unknown() => "<unknown>",
    skir.RecordIdKey_numberWrapper(:final value) => "$value",
    skir.RecordIdKey_stringWrapper(:final value) => _formatStringKey(value),
    skir.RecordIdKey_uuidWrapper(:final value) => "u'$value'",
    skir.RecordIdKey_arrayWrapper(:final value) =>
      "[${value.map(_formatRecordIdValue).join(", ")}]",
    skir.RecordIdKey_objectWrapper(:final value) =>
      "{${value.map((item) => "${_formatStringKey(item.key)}: ${_formatRecordIdValue(item.value)}").join(", ")}}",
  };
}

String _formatRecordIdValue(skir.RecordIdValue value) {
  return switch (value) {
    skir.RecordIdValue_unknown() => "<unknown>",
    skir.RecordIdValue_booleanWrapper(:final value) => "$value",
    skir.RecordIdValue_numberWrapper(:final value) => "$value",
    skir.RecordIdValue_floatWrapper(:final value) => "${value}f",
    skir.RecordIdValue_stringWrapper(:final value) =>
      "'${value.replaceAll("'", r"\'")}'",
    skir.RecordIdValue_arrayWrapper(:final value) =>
      "[${value.map(_formatRecordIdValue).join(", ")}]",
    skir.RecordIdValue_objectWrapper(:final value) =>
      "{${value.map((item) => "${_formatStringKey(item.key)}: ${_formatRecordIdValue(item.value)}").join(", ")}}",
    _ => "NONE",
  };
}

String _formatStringKey(String value) {
  if (_isSimpleId(value)) return value;
  final escaped = value.replaceAll(r"\", r"\\").replaceAll("`", r"\`");
  return "`$escaped`";
}

final _maxInt64 = (BigInt.one << 63) - BigInt.one;
final _minInt64 = -(BigInt.one << 63);

bool _isSimpleId(String value) {
  if (value.isEmpty || !RegExp(r"^[A-Za-z0-9_]+$").hasMatch(value)) {
    return false;
  }

  final number = BigInt.tryParse(value);
  if (number == null) return true;

  return number > _maxInt64 || number < _minInt64;
}

/// Parses the route form `table:key` into the typed Skir identity.
///
/// The key remains opaque. This parser intentionally accepts only the string
/// key form used by panel routes and throws for malformed input.
skir.RecordId recordId(String id) {
  final separator = id.indexOf(":");
  if (separator <= 0 || separator == id.length - 1) {
    throw ArgumentError.value(id, "id", "Expected <table>:<string key>");
  }
  return skir.RecordId(
    table: id.substring(0, separator),
    key: skir.RecordIdKey.wrapString(id.substring(separator + 1)),
  );
}
