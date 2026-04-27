import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/logic/search/search.dart";

void main() {
  group("QuerySelectorDefinitionsX.merge", () {
    test(
      "preserves base selectors first and appends dynamic-only selectors",
      () {
        const baseTag = KeyValueSelectorDefinition(id: "tag", key: "#");
        const dynamicStatus = KeyValueSelectorDefinition(
          id: "status",
          key: "status:",
        );

        final merged = [baseTag].merge([dynamicStatus]);

        expect(merged, [baseTag, dynamicStatus]);
      },
    );

    test("merges enum values uniquely for selectors with the same id", () {
      const base = KeyValueSelectorDefinition(
        id: "status",
        key: "status:",
        value: QuerySelectorValue.enumValue(["open", "closed"]),
      );
      const dynamic = KeyValueSelectorDefinition(
        id: "status",
        key: "status:",
        value: QuerySelectorValue.enumValue(["closed", "draft"]),
      );

      final merged = [base].merge([dynamic]).single;

      final selector = merged as KeyValueSelectorDefinition;
      final value = selector.value as EnumSelectorValue;
      expect(value.possibleValues, ["open", "closed", "draft"]);
    });

    test("free-text dynamic value widens an enum base value", () {
      const base = KeyValueSelectorDefinition(
        id: "status",
        key: "status:",
        value: QuerySelectorValue.enumValue(["open"]),
      );
      const dynamic = KeyValueSelectorDefinition(id: "status", key: "status:");

      final merged = [base].merge([dynamic]).single;

      expect(
        (merged as KeyValueSelectorDefinition).value,
        isA<FreeTextSelectorValue>(),
      );
    });

    test("merges case sensitivity and multiplicity conservatively", () {
      const base = KeyValueSelectorDefinition(
        id: "id",
        key: "id:",
        multiplicity: QueryMultiplicity.multiple,
      );
      const dynamic = KeyValueSelectorDefinition(
        id: "id",
        key: "id:",
        caseSensitive: true,
        multiplicity: QueryMultiplicity.single,
      );

      final merged = [base].merge([dynamic]).single;

      final selector = merged as KeyValueSelectorDefinition;
      expect(selector.caseSensitive, isTrue);
      expect(selector.multiplicity, QueryMultiplicity.single);
    });
  });
}
