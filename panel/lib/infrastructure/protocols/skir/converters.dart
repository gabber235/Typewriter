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
  String get id => _formatRecordIdKey(key);
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
  return "`$value`";
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
  final parts = id.split(":");
  assert(parts.length == 2, "id must be of format `<table>:<id>`");
  return skir.RecordId(
    table: parts[0],
    key: skir.RecordIdKey.wrapString(parts[1]),
  );
}
