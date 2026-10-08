import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("integer admission enforces signed and unsigned widths", () {
    final signedEight = skir.TypeUse.wrapScalar(
      skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedEight),
    );
    final unsignedEight = skir.TypeUse.wrapScalar(
      skir.ScalarKind.createInteger(width: skir.IntegerWidth.unsignedEight),
    );

    expect(_integer("127", signedEight), skir.DataValue.wrapInteger("127"));
    expect(_integer("128", signedEight), isNull);
    expect(_integer("-128", signedEight), skir.DataValue.wrapInteger("-128"));
    expect(_integer("-129", signedEight), isNull);
    expect(_integer("255", unsignedEight), skir.DataValue.wrapInteger("255"));
    expect(_integer("256", unsignedEight), isNull);
    expect(_integer("-1", unsignedEight), isNull);
  });

  test("decimal admission writes canonical lexical values", () {
    final decimal = skir.TypeUse.wrapScalar(skir.ScalarKind.decimal);

    expect(_integer(".5", decimal), skir.DataValue.wrapDecimal("0.5"));
    expect(_integer("01.0", decimal), skir.DataValue.wrapDecimal("1.0"));
    expect(_integer("1.", decimal), isNull);
  });

  test("float admission rejects Float32 overflow", () {
    final float32 = skir.TypeUse.wrapScalar(
      skir.ScalarKind.createFloat(width: skir.FloatWidth.thirtyTwo),
    );
    final float64 = skir.TypeUse.wrapScalar(
      skir.ScalarKind.createFloat(width: skir.FloatWidth.sixtyFour),
    );

    expect(_integer("3.5e38", float32), isNull);
    expect(_integer("3.5e38", float64), skir.DataValue.wrapFloat(3.5e38));
  });

  test("Float32 admission stores the exact narrowed value", () {
    final float32 = skir.TypeUse.wrapScalar(
      skir.ScalarKind.createFloat(width: skir.FloatWidth.thirtyTwo),
    );

    final tenth = _integer("0.1", float32);
    final roundedTen = _integer("9.9999999", float32);

    expect(tenth, skir.DataValue.wrapFloat(0.10000000149011612));
    expect(roundedTen, skir.DataValue.wrapFloat(10));
    expect(portableNumericInputText(current: tenth, expected: float32), "0.1");
    expect(
      portableNumericInputText(current: roundedTen, expected: float32),
      "10",
    );
  });

  test("input acceptance keeps temporary states and rejects invalid text", () {
    final signed = skir.TypeUse.wrapScalar(
      skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedThirtyTwo),
    );

    expect(_accepts("", signed), isTrue);
    expect(_accepts("-", signed), isTrue);
    expect(_accepts("12x", signed), isFalse);
    expect(_accepts("2147483648", signed), isFalse);
  });
}

skir.DataValue? _integer(String text, skir.TypeUse expected) =>
    admitPortableNumericInput(
      current: skir.DataValue.unfilled,
      expected: expected,
      text: text,
    );

bool _accepts(String text, skir.TypeUse expected) =>
    acceptsPortableNumericInput(
      current: skir.DataValue.unfilled,
      expected: expected,
      text: text,
    );
