import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("decimal validation enforces exact minimum and maximum", () {
    const type = DecimalType(minimum: "0.01", maximum: "9.99", scale: 2);

    expect(DecimalValue("0.01").validateAgainst(type), isEmpty);
    expect(DecimalValue("9.99").validateAgainst(type), isEmpty);
    expect(DecimalValue("0.001").validateAgainst(type), isNotEmpty);
    expect(DecimalValue("10").validateAgainst(type), isNotEmpty);
  });

  test("scalar equality retains every declared constraint", () {
    const decimal = DecimalType(minimum: "0", maximum: "10", scale: 2);
    final timestamp = TimestampType(
      minimum: DateTime.utc(2020),
      maximum: DateTime.utc(2030),
    );
    const duration = DurationType(
      minimum: Duration(seconds: 1),
      maximum: Duration(seconds: 10),
    );
    const string = StringType(patterns: [r"^[a-z]+$"]);

    expect(typeExpressionsEqual(decimal, decimal), isTrue);
    expect(
      typeExpressionsEqual(
        decimal,
        const DecimalType(minimum: "1", maximum: "10", scale: 2),
      ),
      isFalse,
    );
    expect(typeExpressionsEqual(timestamp, timestamp), isTrue);
    expect(typeExpressionsEqual(duration, duration), isTrue);
    expect(typeExpressionsEqual(string, string), isTrue);
    expect(typeExpressionsEqual(string, const StringType()), isFalse);
  });
}
