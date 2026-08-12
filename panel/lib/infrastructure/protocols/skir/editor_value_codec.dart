import "dart:typed_data";

import "package:skir_client/skir_client.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/editor_codec_support.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/editor_type_codec.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/editor_value_collection_codec.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as wire;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/kernel/v1/duration.dart"
    as wire_duration;
import "package:typewriter_panel/shared/editors/domain/types/type_diagnostic.dart";
import "package:typewriter_panel/shared/editors/domain/types/type_id.dart";
import "package:typewriter_panel/shared/editors/domain/values/data_value.dart";

final class SkirDataValueCodec {
  const SkirDataValueCodec(this.typeCodec);

  final SkirTypeCodec typeCodec;

  TypeResult<wire.TypedValue> encode(DataValue value) => switch (value) {
    UnitValue() => const TypeResult.success(wire.TypedValue.unit),
    BooleanValue(:final value) => TypeResult.success(
      wire.TypedValue.wrapBoolean(value),
    ),
    IntegerValue(:final value) => _encodeInteger(value),
    FloatValue(:final value) =>
      value.isFinite
          ? TypeResult.success(wire.TypedValue.wrapFloatSixtyFour(value))
          : invalidWire("Float value must be finite"),
    DecimalValue(:final value) =>
      _validDecimal(value)
          ? TypeResult.success(wire.TypedValue.wrapDecimal(value))
          : invalidWire("Decimal value is not canonical"),
    StringValue(:final value) => TypeResult.success(
      wire.TypedValue.wrapString(value),
    ),
    BytesValue(:final value) => TypeResult.success(
      wire.TypedValue.wrapBytes(ByteString.copy(value)),
    ),
    TimestampValue(:final value) => _encodeTimestamp(value),
    DurationValue(:final value) => _encodeDuration(value),
    ListValue(:final values) => SkirDataValueCollectionCodec(
      this,
    ).encodeList(values),
    MapValue(:final entries) => SkirDataValueCollectionCodec(
      this,
    ).encodeMap(entries),
    RecordValue(:final fields) => SkirDataValueCollectionCodec(
      this,
    ).encodeRecord(fields),
    PolymorphicValue(:final concreteType, :final value) => _encodeNamed(
      concreteType,
      value,
    ),
  };

  TypeResult<DataValue> decode(wire.TypedValue? value) {
    if (value == null) return invalidWire("Wire typed value is null");
    return switch (value) {
      wire.TypedValue_unknown() => invalidWire("Unknown wire typed value"),
      wire.TypedValue.unit => const TypeResult.success(UnitValue()),
      wire.TypedValue_booleanWrapper(:final value) => TypeResult.success(
        BooleanValue(value),
      ),
      wire.TypedValue_stringWrapper(:final value) => TypeResult.success(
        StringValue(value),
      ),
      wire.TypedValue_bytesWrapper(:final value) => TypeResult.success(
        BytesValue(Uint8List.fromList(value.asUnmodifiableList)),
      ),
      wire.TypedValue_signedEightWrapper(:final value) => _decodeInteger(
        value,
        -128,
        127,
      ),
      wire.TypedValue_signedSixteenWrapper(:final value) => _decodeInteger(
        value,
        -32768,
        32767,
      ),
      wire.TypedValue_signedThirtyTwoWrapper(:final value) => _decodeInteger(
        value,
        -2147483648,
        2147483647,
      ),
      wire.TypedValue_signedSixtyFourWrapper(:final value) =>
        _decodeSignedSixtyFour(value),
      wire.TypedValue_unsignedEightWrapper(:final value) => _decodeInteger(
        value,
        0,
        255,
      ),
      wire.TypedValue_unsignedSixteenWrapper(:final value) => _decodeInteger(
        value,
        0,
        65535,
      ),
      wire.TypedValue_unsignedThirtyTwoWrapper(:final value) => _decodeInteger(
        value,
        0,
        4294967295,
      ),
      wire.TypedValue_unsignedSixtyFourWrapper(:final value) =>
        _decodeUnsignedSixtyFour(value),
      wire.TypedValue_floatThirtyTwoWrapper(:final value) => _decodeFloat(
        value,
      ),
      wire.TypedValue_floatSixtyFourWrapper(:final value) => _decodeFloat(
        value,
      ),
      wire.TypedValue_decimalWrapper(:final value) => _decodeDecimal(value),
      wire.TypedValue_timestampWrapper(:final value) => _decodeTimestamp(value),
      wire.TypedValue_durationWrapper(:final value) => TypeResult.success(
        DurationValue(Duration(milliseconds: value.duration.milliseconds)),
      ),
      wire.TypedValue_listWrapper(:final value) => SkirDataValueCollectionCodec(
        this,
      ).decodeList(value),
      wire.TypedValue_mapWrapper(:final value) => SkirDataValueCollectionCodec(
        this,
      ).decodeMap(value.entries),
      wire.TypedValue_recordWrapper(:final value) =>
        SkirDataValueCollectionCodec(this).decodeRecord(value.fields),
      wire.TypedValue_namedWrapper(:final value) => _decodeNamed(value),
    };
  }

  TypeResult<wire.TypedValue> _encodeInteger(BigInt value) {
    final signedMinimum = -(BigInt.one << 63);
    final signedMaximum = (BigInt.one << 63) - BigInt.one;
    if (value >= signedMinimum && value <= signedMaximum) {
      return TypeResult.success(
        wire.TypedValue.wrapSignedSixtyFour(value.toInt()),
      );
    }
    final unsignedMaximum = (BigInt.one << 64) - BigInt.one;
    if (!value.isNegative && value <= unsignedMaximum) {
      return TypeResult.success(
        wire.TypedValue.wrapUnsignedSixtyFour(value.toString()),
      );
    }
    return invalidWire("Integer value is outside the 64 bit wire range");
  }

  TypeResult<wire.TypedValue> _encodeTimestamp(DateTime value) {
    if (value.microsecondsSinceEpoch.remainder(1000) != 0) {
      return invalidWire("Timestamp must have millisecond precision");
    }
    return TypeResult.success(wire.TypedValue.wrapTimestamp(value.toUtc()));
  }

  TypeResult<wire.TypedValue> _encodeDuration(Duration value) {
    if (value.inMicroseconds.remainder(1000) != 0) {
      return invalidWire("Duration must have millisecond precision");
    }
    return TypeResult.success(
      wire.TypedValue.createDuration(
        duration: wire_duration.Duration(milliseconds: value.inMilliseconds),
      ),
    );
  }

  TypeResult<wire.TypedValue> _encodeNamed(
    ResolvedTypeRef type,
    DataValue value,
  ) => combineResults(
    typeCodec.encodeReference(type),
    encode(value),
    (reference, encoded) =>
        wire.TypedValue.createNamed(tag: reference, payload: encoded),
  );

  TypeResult<DataValue> _decodeInteger(int value, int minimum, int maximum) {
    if (value < minimum || value > maximum) {
      return invalidWire("Integer payload is outside its tagged width");
    }
    return TypeResult.success(IntegerValue(BigInt.from(value)));
  }

  TypeResult<DataValue> _decodeUnsignedSixtyFour(String source) {
    final value = BigInt.tryParse(source);
    final maximum = (BigInt.one << 64) - BigInt.one;
    if (value == null || value.isNegative || value > maximum) {
      return invalidWire("Unsigned 64 bit payload is invalid");
    }
    return TypeResult.success(IntegerValue(value));
  }

  TypeResult<DataValue> _decodeSignedSixtyFour(int source) {
    final value = BigInt.from(source);
    final minimum = -(BigInt.one << 63);
    final maximum = (BigInt.one << 63) - BigInt.one;
    if (value < minimum || value > maximum) {
      return invalidWire("Signed 64 bit payload is invalid");
    }
    return TypeResult.success(IntegerValue(value));
  }

  TypeResult<DataValue> _decodeTimestamp(DateTime value) {
    if (value.microsecondsSinceEpoch.remainder(1000) != 0) {
      return invalidWire("Timestamp must have millisecond precision");
    }
    return TypeResult.success(TimestampValue(value));
  }

  TypeResult<DataValue> _decodeFloat(double value) => value.isFinite
      ? TypeResult.success(FloatValue(value))
      : invalidWire("Float payload must be finite");

  TypeResult<DataValue> _decodeDecimal(String value) => _validDecimal(value)
      ? TypeResult.success(DecimalValue(value))
      : invalidWire("Decimal payload is not canonical");

  TypeResult<DataValue> _decodeNamed(wire.TypedNamedValue value) =>
      combineResults(
        typeCodec.decodeReference(value.tag),
        decode(value.payload),
        (type, decoded) => PolymorphicValue(concreteType: type, value: decoded),
      );

  bool _validDecimal(String value) =>
      RegExp(r"^-?(0|[1-9][0-9]*)(\.[0-9]+)?$").hasMatch(value);
}
