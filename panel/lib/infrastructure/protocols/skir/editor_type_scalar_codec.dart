import "package:typewriter_panel/infrastructure/protocols/skir/editor_codec_support.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as wire;
import "package:typewriter_panel/typewriter_panel.dart";

// ignore: avoid_classes_with_only_static_members
abstract final class SkirTypeScalarCodec {
  static TypeResult<wire.TypeExpression> encodeString(StringType value) {
    if (value.patterns.length > 1) {
      return invalidWire(
        "Multiple string patterns have no wire representation",
      );
    }
    return TypeResult.success(
      wire.TypeExpression.createString(
        minimumLength: value.minimumLength,
        maximumLength: value.maximumLength,
        pattern: value.patterns.isEmpty ? null : value.patterns.single,
        allowedValues: const [],
      ),
    );
  }

  static TypeResult<TypeExpression> decodeString(wire.StringConstraints value) {
    if (value.allowedValues.isNotEmpty) {
      return invalidWire(
        "Allowed string values are not supported by the panel type",
      );
    }
    return TypeResult.success(
      StringType(
        minimumLength: value.minimumLength,
        maximumLength: value.maximumLength,
        patterns: [?value.pattern],
      ),
    );
  }

  static TypeResult<wire.TypeExpression> encodeInteger(IntegerType value) {
    final constraints = numericConstraints(
      minimum: value.minimum?.toString(),
      maximum: value.maximum?.toString(),
    );
    final width = encodeIntegerWidth(value.width);
    return TypeResult.success(
      value.width.signed
          ? wire.TypeExpression.createSignedInteger(
              width: width,
              constraints: constraints,
            )
          : wire.TypeExpression.createUnsignedInteger(
              width: width,
              constraints: constraints,
            ),
    );
  }

  static TypeResult<TypeExpression> decodeInteger(
    wire.IntegerType value,
    bool signed,
  ) {
    final constraints = _decodeNumeric(value.constraints, BigInt.tryParse);
    if (constraints case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    final bounds = constraints.valueOrNull!;
    final width = decodeIntegerWidth(value.width, signed);
    if (width == null) return invalidWire("Unknown integer width");
    return TypeResult.success(
      IntegerType(width: width, minimum: bounds.$1, maximum: bounds.$2),
    );
  }

  static TypeResult<wire.TypeExpression> encodeFloat(FloatType value) =>
      TypeResult.success(
        wire.TypeExpression.createFloat(
          width: value.width == FloatWidth.float32
              ? wire.FloatWidth.thirtyTwoBits
              : wire.FloatWidth.sixtyFourBits,
          constraints: numericConstraints(
            minimum: value.minimum?.toString(),
            maximum: value.maximum?.toString(),
          ),
        ),
      );

  static TypeResult<TypeExpression> decodeFloat(wire.FloatType value) {
    final constraints = _decodeNumeric(value.constraints, double.tryParse);
    if (constraints case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    final width = switch (value.width) {
      wire.FloatWidth.thirtyTwoBits => FloatWidth.float32,
      wire.FloatWidth.sixtyFourBits => FloatWidth.float64,
      _ => null,
    };
    if (width == null) return invalidWire("Unknown float width");
    final bounds = constraints.valueOrNull!;
    return TypeResult.success(
      FloatType(width: width, minimum: bounds.$1, maximum: bounds.$2),
    );
  }

  static TypeResult<wire.TypeExpression> encodeDecimal(DecimalType value) {
    if (value.scale != null) {
      return invalidWire("Decimal scale has no wire representation");
    }
    return TypeResult.success(
      wire.TypeExpression.createDecimal(
        minimum: value.minimum,
        minimumInclusive: true,
        maximum: value.maximum,
        maximumInclusive: true,
        multipleOf: null,
      ),
    );
  }

  static TypeResult<TypeExpression> decodeDecimal(
    wire.NumericConstraints value,
  ) {
    final constraints = _decodeNumeric(value, _validDecimal);
    if (constraints case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    final bounds = constraints.valueOrNull!;
    return TypeResult.success(
      DecimalType(minimum: bounds.$1, maximum: bounds.$2),
    );
  }

  static wire.NumericConstraints numericConstraints({
    String? minimum,
    String? maximum,
  }) => wire.NumericConstraints(
    minimum: minimum,
    minimumInclusive: true,
    maximum: maximum,
    maximumInclusive: true,
    multipleOf: null,
  );

  static wire.IntegerWidth encodeIntegerWidth(IntegerWidth width) =>
      switch (width.bits) {
        8 => wire.IntegerWidth.eightBits,
        16 => wire.IntegerWidth.sixteenBits,
        32 => wire.IntegerWidth.thirtyTwoBits,
        _ => wire.IntegerWidth.sixtyFourBits,
      };

  static IntegerWidth? decodeIntegerWidth(
    wire.IntegerWidth width,
    bool signed,
  ) {
    final bits = switch (width) {
      wire.IntegerWidth.eightBits => 8,
      wire.IntegerWidth.sixteenBits => 16,
      wire.IntegerWidth.thirtyTwoBits => 32,
      wire.IntegerWidth.sixtyFourBits => 64,
      _ => null,
    };
    return switch ((bits, signed)) {
      (8, true) => IntegerWidth.signed8,
      (16, true) => IntegerWidth.signed16,
      (32, true) => IntegerWidth.signed32,
      (64, true) => IntegerWidth.signed64,
      (8, false) => IntegerWidth.unsigned8,
      (16, false) => IntegerWidth.unsigned16,
      (32, false) => IntegerWidth.unsigned32,
      (64, false) => IntegerWidth.unsigned64,
      _ => null,
    };
  }

  static TypeResult<(T?, T?)> _decodeNumeric<T>(
    wire.NumericConstraints value,
    T? Function(String source) parse,
  ) {
    if (!value.minimumInclusive ||
        !value.maximumInclusive ||
        value.multipleOf != null) {
      return invalidWire(
        "Exclusive bounds and multiples are not supported by the panel type",
      );
    }
    final minimum = value.minimum == null ? null : parse(value.minimum!);
    final maximum = value.maximum == null ? null : parse(value.maximum!);
    if (value.minimum != null && minimum == null) {
      return invalidWire("Invalid numeric minimum");
    }
    if (value.maximum != null && maximum == null) {
      return invalidWire("Invalid numeric maximum");
    }
    return TypeResult.success((minimum, maximum));
  }

  static String? _validDecimal(String source) =>
      RegExp(r"^-?(0|[1-9][0-9]*)(\.[0-9]+)?$").hasMatch(source)
      ? source
      : null;
}
