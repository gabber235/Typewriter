import "dart:typed_data";

import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "data_value.freezed.dart";

/// Tagged runtime data exchanged by the editor domain.
///
/// The variants preserve type information that JSON and Dart primitives do not
/// carry reliably, such as arbitrary precision integers, map keys, timestamps,
/// and nominal values. Editor owners use these values as the canonical payload
/// for reading, validation, mutation, presentation, and persistence.
@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
sealed class DataValue with _$DataValue {
  const DataValue._();

  const factory DataValue.unit() = UnitValue;

  const factory DataValue.boolean(bool value) = BooleanValue;

  factory DataValue.integer(BigInt value) = IntegerValue;

  const factory DataValue.float(double value) = FloatValue;

  @Assert(
    "RegExp(r\"^-?(0|[1-9][0-9]*)(\\.[0-9]+)?\$\").hasMatch(value)",
    "Decimal value must use canonical decimal syntax.",
  )
  factory DataValue.decimal(String value) = DecimalValue;

  const factory DataValue.string(String value) = StringValue;

  factory DataValue.bytes(Uint8List value) = BytesValue;

  factory DataValue.timestamp(DateTime value) = TimestampValue;

  const factory DataValue.duration(Duration value) = DurationValue;

  const factory DataValue.list(List<DataValue> values) = ListValue;

  const factory DataValue.map(List<DataMapEntry> entries) = MapValue;

  @Implements<RecordValue>()
  const factory DataValue.record(Map<String, DataValue> fields) = _RecordValue;

  const factory DataValue.polymorphic({
    required ResolvedTypeRef concreteType,
    required DataValue value,
  }) = PolymorphicValue;

  const factory DataValue.reference(skir.ResourceId id) = ReferenceValue;
}

/// A string keyed object value whose fields can be addressed by [DataPath].
///
/// Use [withField] and [withoutField] to derive edits. They return new values,
/// so callers do not mutate the value currently owned by an editor.
abstract interface class RecordValue implements DataValue {
  factory RecordValue(Map<String, DataValue> fields) =>
      DataValue.record(fields) as RecordValue;

  Map<String, DataValue> get fields;
}

/// Byte data copied at construction so the value cannot share mutable input.
@freezed
class BytesValue extends DataValue with _$BytesValue {
  BytesValue(Uint8List value) : value = Uint8List.fromList(value), super._();

  final Uint8List value;
}

/// A timestamp normalized to UTC for stable equality and serialization.
@freezed
class TimestampValue extends DataValue with _$TimestampValue {
  TimestampValue(DateTime value) : value = value.toUtc(), super._();

  final DateTime value;
}

/// One ordered key and value pair in a [MapValue].
///
/// A list is used instead of a Dart map because typed data permits arbitrary
/// [DataValue] keys and preserves entry order.
@freezed
abstract class DataMapEntry with _$DataMapEntry {
  const factory DataMapEntry({
    required DataValue key,
    required DataValue value,
  }) = _DataMapEntry;
}

/// Copy on write operations for record values used by editor mutations.
extension RecordValueMutation on RecordValue {
  RecordValue withField(String name, DataValue value) =>
      RecordValue({...fields, name: value});

  RecordValue withoutField(String name) =>
      RecordValue(Map.of(fields)..remove(name));

  String requiredStringField(String name) => switch (fields[name]) {
    StringValue(:final value) => value,
    _ => throw StateError("Record field '$name' must be a string"),
  };
}
