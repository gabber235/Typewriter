import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/logic/search/query/query.dart";

void main() {
  test("case insensitive selector matches mixed case", () {
    final engine = QueryEngine([
      const KeyValueSelectorDefinition(id: "title", key: "title"),
    ]);

    final result = engine.parse("Title:\"A\"");

    expect(result.selectorMatches, hasLength(1));
    final match = result.selectorMatches.single as KeyValueSelectorMatch;
    expect(match.value, "A");
  });

  test("case sensitive selector requires exact case", () {
    final engine = QueryEngine([
      const KeyValueSelectorDefinition(
        id: "title",
        key: "title",
        caseSensitive: true,
      ),
    ]);

    final mixed = engine.parse("Title:\"A\"");
    final exact = engine.parse("title:\"A\"");

    expect(mixed.selectorMatches, isEmpty);
    expect(exact.selectorMatches, hasLength(1));
  });

  test("operators remain case insensitive", () {
    final engine = QueryEngine([
      const SymbolSelectorDefinition(id: "tag", symbol: "#"),
    ]);

    final result = engine.parse("nOt #a aNd #b oR #c");

    expect(result.expression, isA<QueryOrNode>());
  });

  test("mixed symbolic and word operators remain supported", () {
    final engine = QueryEngine([
      const SymbolSelectorDefinition(id: "tag", symbol: "#"),
    ]);

    final result = engine.parse("!#a Or #b && #c");

    expect(result.expression, isA<QueryOrNode>());
  });
}
