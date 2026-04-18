import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/logic/search/query/query.dart";
import "test_query_catalog.dart";

void main() {
  test("default catalog contains planned selectors", () {
    final selectors = buildDefaultQuerySelectorsForTest();

    final ids = selectors.map((selector) => selector.id).toSet();
    final symbols = selectors
        .whereType<SymbolSelectorDefinition>()
        .map((selector) => selector.symbol)
        .toSet();

    expect(ids.contains("title"), isTrue);
    expect(ids.contains("id"), isTrue);
    expect(ids.contains("role"), isTrue);
    expect(ids.contains("path"), isTrue);
    expect(symbols.contains("#"), isTrue);
    expect(symbols.contains("@"), isTrue);
    expect(symbols.contains("~"), isTrue);
  });

  test("default catalog has no duplicate ids", () {
    final selectors = buildDefaultQuerySelectorsForTest();
    final ids = selectors.map((selector) => selector.id).toList();
    final unique = ids.toSet();

    expect(unique.length, ids.length);
  });

  test("default case sensitivity is false", () {
    final selectors = buildDefaultQuerySelectorsForTest();

    expect(selectors.every((selector) => !selector.caseSensitive), isTrue);
  });

  test("default catalog can parse mixed selector query", () {
    final selectors = buildDefaultQuerySelectorsForTest();
    final engine = QueryEngine(selectors);

    final result = engine.parse("#quest title:\"Book\" role:admin hello");

    expect(result.selectorMatches, hasLength(3));
    expect(result.textTerms, hasLength(1));
    expect(result.textTerms.single.text, "hello");
  });
}
