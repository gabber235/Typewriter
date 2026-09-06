import "dart:math";

import "package:flutter/material.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

extension SkirColorExtension on skir.Color {
  Color toFlutterColor() {
    return Color(argb.toUnsigned(32));
  }
}

extension FlutterColorToSkirExtension on Color {
  skir.Color toSkirColor() {
    return skir.Color(argb: toARGB32().toSigned(32));
  }
}

extension RecordIdExtension on skir.RecordId {
  /// The opaque string key used by routes and resource references.
  String get id => switch (key) {
    skir.RecordIdKey_stringWrapper(:final value) => value,
    _ => throw StateError("Expected a string record key for $table"),
  };

  String toSurrealQl() =>
      "${_formatStringKey(table)}:${_formatRecordIdKey(key)}";
}

enum AuthoringResource { book, tag, page, element }

final _resourceRandom = Random.secure();
const _resourceAlphabet = "abcdefghijklmnopqrstuvwxyz0123456789";

/// Allocate once before batch submission, preserving the ID through retries.
skir.RecordId newResourceId(AuthoringResource resource) => skir.RecordId(
  table: resource.name,
  key: skir.RecordIdKey.wrapString(
    String.fromCharCodes([
      for (var index = 0; index < 20; index++)
        _resourceAlphabet.codeUnitAt(_resourceRandom.nextInt(36)),
    ]),
  ),
);

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
