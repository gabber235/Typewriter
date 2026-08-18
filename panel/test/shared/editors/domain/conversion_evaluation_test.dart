import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("Conversion evaluation", () {
    test("scalar rules convert supported numeric values", () {
      final result = (const ConversionRule.scalar(
        ScalarConversion.integerToDecimal,
      )).evaluate(IntegerValue(BigInt.from(42)));

      expect(result, isA<ConversionSuccess>());
      expect((result as ConversionSuccess).value, DecimalValue("42"));
    });

    test("record construction projects and converts source fields", () {
      final input = RecordValue({
        "id": const StringValue("entry"),
        "count": IntegerValue(BigInt.from(3)),
      });
      const rule = ConversionRule.record({
        "name": ConversionRule.field(name: "id", rule: ConversionRule.input()),
        "amount": ConversionRule.field(
          name: "count",
          rule: ConversionRule.scalar(ScalarConversion.integerToFloat),
        ),
      });

      final result = rule.evaluate(input) as ConversionSuccess;

      expect(
        result.value,
        RecordValue({
          "name": const StringValue("entry"),
          "amount": const FloatValue(3),
        }),
      );
    });

    test("list and polymorphic rules preserve collection structure", () {
      final sourceType = _type("SourceIds");
      final targetType = _type("TargetIds");
      final rule = ConversionRule.polymorphic([
        ConversionPolymorphicCase(
          sourceType: sourceType,
          targetType: targetType,
          rule: const ConversionRule.list(ConversionRule.input()),
        ),
      ]);
      final input = PolymorphicValue(
        concreteType: sourceType,
        value: ListValue([
          const StringValue("first"),
          const StringValue("second"),
        ]),
      );

      final result = rule.evaluate(input) as ConversionSuccess;

      expect(
        result.value,
        PolymorphicValue(
          concreteType: targetType,
          value: ListValue([
            const StringValue("first"),
            const StringValue("second"),
          ]),
        ),
      );
    });

    test("composed rules feed each result into the next rule", () {
      const rule = ConversionRule.compose([
        ConversionRule.scalar(ScalarConversion.integerToDecimal),
        ConversionRule.scalar(ScalarConversion.decimalToFloat),
      ]);

      final result = rule.evaluate(IntegerValue(BigInt.from(7)));

      expect((result as ConversionSuccess).value, const FloatValue(7));
    });

    test("invalid source values return conversion diagnostics", () {
      final result = (const ConversionRule.scalar(
        ScalarConversion.integerToFloat,
      )).evaluate(const BooleanValue(true));

      expect(result, isA<ConversionFailure>());
      expect(
        (result as ConversionFailure).diagnostics.single.code,
        TypeDiagnosticCode.conversionFailed,
      );
    });

    test("realm rules remain explicit and unexecuted", () {
      final result = (const ConversionRule.realm()).evaluate(
        const StringValue("value"),
      );

      expect(result, isA<ConversionUnavailable>());
    });

    test("applying a realm conversion returns unavailable", () {
      final source = _type("source");
      final target = _type("target");
      final conversion = _conversion(
        "remote",
        source,
        target,
        locality: ConversionLocality.realm,
      );

      final result = ConversionGraph([
        conversion,
      ]).apply(const StringValue("value"), [conversion]);

      expect(result, isA<ConversionUnavailable>());
    });
  });
}

ResolvedTypeRef _type(String name) => ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "test", name: name),
  revision: 1,
);

ConversionDefinition _conversion(
  String id,
  ResolvedTypeRef source,
  ResolvedTypeRef target, {
  ConversionSafety safety = ConversionSafety.lossless,
  bool fallible = false,
  ConversionLocality locality = ConversionLocality.local,
  int cost = 1,
}) => ConversionDefinition(
  id: ConversionId(namespace: "test", name: id),
  source: source,
  target: target,
  rule: const ConversionRule.input(),
  safety: safety,
  fallible: fallible,
  locality: locality,
  cost: cost,
);
