import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "type_expression.freezed.dart";

@freezed
sealed class TypeExpression with _$TypeExpression {
  const TypeExpression._();

  const factory TypeExpression.any() = AnyType;

  const factory TypeExpression.unit() = UnitType;

  const factory TypeExpression.boolean() = BooleanType;

  const factory TypeExpression.string({
    int? minimumLength,
    int? maximumLength,
    @Default([]) List<String> patterns,
  }) = StringType;

  const factory TypeExpression.bytes({int? minimumLength, int? maximumLength}) =
      BytesType;

  const factory TypeExpression.integer({
    required IntegerWidth width,
    BigInt? minimum,
    BigInt? maximum,
  }) = IntegerType;

  const factory TypeExpression.float({
    required FloatWidth width,
    double? minimum,
    double? maximum,
  }) = FloatType;

  const factory TypeExpression.decimal({
    String? minimum,
    String? maximum,
    int? scale,
  }) = DecimalType;

  const factory TypeExpression.timestamp({
    DateTime? minimum,
    DateTime? maximum,
  }) = TimestampType;

  const factory TypeExpression.duration({
    Duration? minimum,
    Duration? maximum,
  }) = DurationType;

  const factory TypeExpression.enumeration({
    required TypeExpression valueType,
    required List<DataValue> values,
  }) = EnumType;

  const factory TypeExpression.list({
    required TypeExpression element,
    int? minimumLength,
    int? maximumLength,
    @Default(false) bool unique,
  }) = ListType;

  const factory TypeExpression.map({
    required TypeExpression key,
    required TypeExpression value,
    int? minimumLength,
    int? maximumLength,
  }) = MapType;

  const factory TypeExpression.record({
    required Map<String, TypeField> fields,
    @Default(true) bool closed,
  }) = RecordType;

  const factory TypeExpression.named(ResolvedTypeRef reference) = NamedType;

  @Assert("name != \"\"", "Parameter name must not be empty.")
  const factory TypeExpression.parameter(String name) = ParameterType;
}

enum IntegerWidth {
  signed8(bits: 8, signed: true),
  signed16(bits: 16, signed: true),
  signed32(bits: 32, signed: true),
  signed64(bits: 64, signed: true),
  unsigned8(bits: 8, signed: false),
  unsigned16(bits: 16, signed: false),
  unsigned32(bits: 32, signed: false),
  unsigned64(bits: 64, signed: false);

  const IntegerWidth({required this.bits, required this.signed});

  final int bits;
  final bool signed;

  BigInt get minimum => signed ? -(BigInt.one << (bits - 1)) : BigInt.zero;
  BigInt get maximum => signed
      ? (BigInt.one << (bits - 1)) - BigInt.one
      : (BigInt.one << bits) - BigInt.one;
}

enum FloatWidth { float32, float64 }

@freezed
abstract class TypeField with _$TypeField {
  const factory TypeField({
    required String name,
    required TypeExpression type,
    DataValue? initialValue,
  }) = _TypeField;
}
