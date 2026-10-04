import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("enum JSON preserves its explicit value type", () {
    final type = EnumType(
      valueType: const StringType(minimumLength: 1),
      values: const [StringValue("open"), StringValue("closed")],
    );
    const converter = TypeExpressionJsonConverter();
    final encoded = converter.toJson(type);
    final decoded = converter.fromJson(encoded);

    expect(typeExpressionsEqual(decoded, type), isTrue);
    expect(encoded["valueType"], isA<Map<String, Object?>>());
  });

  test("records are complete and enums accept only declared values", () {
    final record = RecordType(
      fields: {
        "state": TypeField(
          name: "state",
          type: EnumType(
            valueType: const StringType(),
            values: const [StringValue("open"), StringValue("closed")],
          ),
        ),
      },
    );

    expect(
      RecordValue({}).validateAgainst(record).single.code,
      TypeDiagnosticCode.missingField,
    );
    expect(
      RecordValue({"state": const StringValue("open")}).validateAgainst(record),
      isEmpty,
    );
    expect(
      RecordValue({"state": const StringValue("unknown")})
          .validateAgainst(record),
      isNotEmpty,
    );
  });

  test(
    "duration values and constraints require exact millisecond precision",
    () {
      const type = DurationType(maximum: Duration(milliseconds: 5));
      const invalidType = DurationType(maximum: Duration(microseconds: 5001));

      expect(
        (const DurationValue(Duration(milliseconds: 1))).validateAgainst(type),
        isEmpty,
      );
      expect(
        (const DurationValue(Duration(microseconds: 1001)))
            .validateAgainst(type),
        isNotEmpty,
      );
      expect(invalidType.validateConstraints(const {}), isNotEmpty);
    },
  );
}
