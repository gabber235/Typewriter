import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("integer admission enforces signed and unsigned widths", () {
    final signedEight = types.TypeUse.wrapScalar(
      types.ScalarKind.createInteger(width: types.IntegerWidth.signedEight),
    );
    final unsignedEight = types.TypeUse.wrapScalar(
      types.ScalarKind.createInteger(width: types.IntegerWidth.unsignedEight),
    );

    expect(_integer("127", signedEight), types.DataValue.wrapInteger("127"));
    expect(_integer("128", signedEight), isNull);
    expect(_integer("-128", signedEight), types.DataValue.wrapInteger("-128"));
    expect(_integer("-129", signedEight), isNull);
    expect(_integer("255", unsignedEight), types.DataValue.wrapInteger("255"));
    expect(_integer("256", unsignedEight), isNull);
    expect(_integer("-1", unsignedEight), isNull);
  });

  test("decimal admission writes canonical lexical values", () {
    final decimal = types.TypeUse.wrapScalar(types.ScalarKind.decimal);

    expect(_integer(".5", decimal), types.DataValue.wrapDecimal("0.5"));
    expect(_integer("01.0", decimal), types.DataValue.wrapDecimal("1.0"));
    expect(_integer("1.", decimal), isNull);
  });

  test("float admission rejects Float32 overflow", () {
    final float32 = types.TypeUse.wrapScalar(
      types.ScalarKind.createFloat(width: types.FloatWidth.thirtyTwo),
    );
    final float64 = types.TypeUse.wrapScalar(
      types.ScalarKind.createFloat(width: types.FloatWidth.sixtyFour),
    );

    expect(_integer("3.5e38", float32), isNull);
    expect(_integer("3.5e38", float64), types.DataValue.wrapFloat(3.5e38));
  });

  test("Float32 admission stores the exact narrowed value", () {
    final float32 = types.TypeUse.wrapScalar(
      types.ScalarKind.createFloat(width: types.FloatWidth.thirtyTwo),
    );

    final tenth = _integer("0.1", float32);
    final roundedTen = _integer("9.9999999", float32);

    expect(tenth, types.DataValue.wrapFloat(0.10000000149011612));
    expect(roundedTen, types.DataValue.wrapFloat(10));
    expect(portableNumericInputText(current: tenth, expected: float32), "0.1");
    expect(
      portableNumericInputText(current: roundedTen, expected: float32),
      "10",
    );
  });

  test("input acceptance keeps temporary states and rejects invalid text", () {
    final signed = types.TypeUse.wrapScalar(
      types.ScalarKind.createInteger(width: types.IntegerWidth.signedThirtyTwo),
    );

    expect(_accepts("", signed), isTrue);
    expect(_accepts("-", signed), isTrue);
    expect(_accepts("12x", signed), isFalse);
    expect(_accepts("2147483648", signed), isFalse);
  });
}

types.DataValue? _integer(String text, types.TypeUse expected) =>
    admitPortableNumericInput(
      current: types.DataValue.unfilled,
      expected: expected,
      text: text,
    );

bool _accepts(String text, types.TypeUse expected) =>
    acceptsPortableNumericInput(
      current: types.DataValue.unfilled,
      expected: expected,
      text: text,
    );
