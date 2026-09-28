import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/editor_type_scalar_codec.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as wire;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("unbounded numeric constraints accept absent inclusivity flags", () {
    final constraints = wire.NumericConstraints.defaultInstance;

    expect(
      SkirTypeScalarCodec.decodeFloat(
        wire.FloatType(
          width: wire.FloatWidth.sixtyFourBits,
          constraints: constraints,
        ),
      ).valueOrNull,
      const FloatType(width: FloatWidth.float64),
    );
    expect(
      SkirTypeScalarCodec.decodeInteger(
        wire.IntegerType(
          width: wire.IntegerWidth.thirtyTwoBits,
          constraints: constraints,
        ),
        true,
      ).valueOrNull,
      const IntegerType(width: IntegerWidth.signed32),
    );
  });

  test("exclusive numeric bounds remain unsupported", () {
    final constraints = wire.NumericConstraints(
      minimum: "1",
      minimumInclusive: false,
      maximum: null,
      maximumInclusive: false,
      multipleOf: null,
    );

    expect(
      SkirTypeScalarCodec.decodeFloat(
        wire.FloatType(
          width: wire.FloatWidth.sixtyFourBits,
          constraints: constraints,
        ),
      ),
      isA<TypeFailure<TypeExpression>>(),
    );
  });
}
