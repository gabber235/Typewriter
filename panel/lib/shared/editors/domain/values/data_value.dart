import "dart:typed_data";

import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "data_value.freezed.dart";

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
}

abstract interface class RecordValue implements DataValue {
  factory RecordValue(Map<String, DataValue> fields) =>
      DataValue.record(fields) as RecordValue;

  Map<String, DataValue> get fields;
}

@freezed
class BytesValue extends DataValue with _$BytesValue {
  BytesValue(Uint8List value) : value = Uint8List.fromList(value), super._();

  @override
  final Uint8List value;
}

@freezed
class TimestampValue extends DataValue with _$TimestampValue {
  TimestampValue(DateTime value) : value = value.toUtc(), super._();

  @override
  final DateTime value;
}

@freezed
abstract class DataMapEntry with _$DataMapEntry {
  const factory DataMapEntry({
    required DataValue key,
    required DataValue value,
  }) = _DataMapEntry;
}

extension RecordValueMutation on RecordValue {
  RecordValue withField(String name, DataValue value) =>
      RecordValue({...fields, name: value});

  RecordValue withoutField(String name) =>
      RecordValue(Map.of(fields)..remove(name));
}
