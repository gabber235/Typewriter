import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("numeric steps preserve wide integers and exact decimal increments", () {
    final integer = skir.TypeUse.wrapScalar(
      skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedSixtyFour),
    );
    expect(
      stepPortableNumericValue(
        current: skir.DataValue.wrapInteger("9007199254740993"),
        step: skir.DataValue.wrapInteger("1"),
        expected: integer,
        direction: 1,
      ),
      skir.DataValue.wrapInteger("9007199254740994"),
    );
    expect(
      stepPortableNumericValue(
        current: skir.DataValue.wrapDecimal("10000000000000000.01"),
        step: skir.DataValue.wrapDecimal("0.01"),
        expected: skir.TypeUse.wrapScalar(skir.ScalarKind.decimal),
        direction: 1,
      ),
      skir.DataValue.wrapDecimal("10000000000000000.02"),
    );
    expect(
      comparePortableNumericValues(
        skir.DataValue.wrapDecimal("10000000000000000.01"),
        skir.DataValue.wrapDecimal("10000000000000000.02"),
      ),
      -1,
    );
    expect(
      stepPortableNumericValue(
        current: skir.DataValue.wrapInteger("9223372036854775807"),
        step: skir.DataValue.wrapInteger("1"),
        expected: integer,
        direction: 1,
      ),
      isNull,
    );
  });

  test("integer admission enforces signed and unsigned widths", () {
    final signedEight = skir.TypeUse.wrapScalar(
      skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedEight),
    );
    final unsignedEight = skir.TypeUse.wrapScalar(
      skir.ScalarKind.createInteger(width: skir.IntegerWidth.unsignedEight),
    );

    expect(
      admitPortableNumericInput(
        current: skir.DataValue.unfilled,
        expected: signedEight,
        text: "127",
      ),
      skir.DataValue.wrapInteger("127"),
    );
    expect(
      admitPortableNumericInput(
        current: skir.DataValue.unfilled,
        expected: signedEight,
        text: "128",
      ),
      isNull,
    );
    expect(
      admitPortableNumericInput(
        current: skir.DataValue.unfilled,
        expected: signedEight,
        text: "-128",
      ),
      skir.DataValue.wrapInteger("-128"),
    );
    expect(
      admitPortableNumericInput(
        current: skir.DataValue.unfilled,
        expected: signedEight,
        text: "-129",
      ),
      isNull,
    );
    expect(
      admitPortableNumericInput(
        current: skir.DataValue.unfilled,
        expected: unsignedEight,
        text: "255",
      ),
      skir.DataValue.wrapInteger("255"),
    );
    expect(
      admitPortableNumericInput(
        current: skir.DataValue.unfilled,
        expected: unsignedEight,
        text: "256",
      ),
      isNull,
    );
    expect(
      admitPortableNumericInput(
        current: skir.DataValue.unfilled,
        expected: unsignedEight,
        text: "-1",
      ),
      isNull,
    );
  });

  test("decimal admission writes canonical lexical values", () {
    final decimal = skir.TypeUse.wrapScalar(skir.ScalarKind.decimal);

    expect(
      admitPortableNumericInput(
        current: skir.DataValue.unfilled,
        expected: decimal,
        text: ".5",
      ),
      skir.DataValue.wrapDecimal("0.5"),
    );
    expect(
      admitPortableNumericInput(
        current: skir.DataValue.unfilled,
        expected: decimal,
        text: "01.0",
      ),
      skir.DataValue.wrapDecimal("1.0"),
    );
    expect(
      admitPortableNumericInput(
        current: skir.DataValue.unfilled,
        expected: decimal,
        text: "1.",
      ),
      isNull,
    );
  });

  test("float admission rejects Float32 overflow", () {
    final float32 = skir.TypeUse.wrapScalar(
      skir.ScalarKind.createFloat(width: skir.FloatWidth.thirtyTwo),
    );
    final float64 = skir.TypeUse.wrapScalar(
      skir.ScalarKind.createFloat(width: skir.FloatWidth.sixtyFour),
    );

    expect(
      admitPortableNumericInput(
        current: skir.DataValue.unfilled,
        expected: float32,
        text: "3.5e38",
      ),
      isNull,
    );
    expect(
      admitPortableNumericInput(
        current: skir.DataValue.unfilled,
        expected: float64,
        text: "3.5e38",
      ),
      skir.DataValue.wrapFloat(3.5e38),
    );
  });

  test("Float32 admission stores the exact narrowed value", () {
    final float32 = skir.TypeUse.wrapScalar(
      skir.ScalarKind.createFloat(width: skir.FloatWidth.thirtyTwo),
    );

    final tenth = admitPortableNumericInput(
      current: skir.DataValue.unfilled,
      expected: float32,
      text: "0.1",
    );
    final roundedTen = admitPortableNumericInput(
      current: skir.DataValue.unfilled,
      expected: float32,
      text: "9.9999999",
    );

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

    expect(
      acceptsPortableNumericInput(
        current: skir.DataValue.unfilled,
        expected: signed,
        text: "",
      ),
      isTrue,
    );
    expect(
      acceptsPortableNumericInput(
        current: skir.DataValue.unfilled,
        expected: signed,
        text: "-",
      ),
      isTrue,
    );
    expect(
      acceptsPortableNumericInput(
        current: skir.DataValue.unfilled,
        expected: signed,
        text: "12x",
      ),
      isFalse,
    );
    expect(
      acceptsPortableNumericInput(
        current: skir.DataValue.unfilled,
        expected: signed,
        text: "2147483648",
      ),
      isFalse,
    );
  });
}
