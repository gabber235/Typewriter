import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/logic/search/query/query.dart";

void main() {
  final selectors = <QuerySelectorDefinition>[
    const SymbolSelectorDefinition(id: "tag", symbol: "#"),
  ];

  test("unclosed parenthesis returns warning", () {
    final engine = QueryEngine(selectors);

    final result = engine.parse("(#a AND #b");

    expect(result.selectorMatches, hasLength(2));
    expect(result.issues.isNotEmpty, isTrue);
    expect(
      result.issues.any((issue) => issue.severity == QuerySeverity.warning),
      isTrue,
    );
    expect(result.issues.any((issue) => issue.range != null), isTrue);
  });

  test("trailing operator returns warning", () {
    final engine = QueryEngine(selectors);

    final result = engine.parse("#a AND");

    expect(result.selectorMatches, hasLength(1));
    expect(result.issues.isNotEmpty, isTrue);
    expect(
      result.issues.any((issue) => issue.severity == QuerySeverity.warning),
      isTrue,
    );
    expect(result.issues.any((issue) => issue.range != null), isTrue);
  });

  test("invalid token keeps parse result and reports warning", () {
    final engine = QueryEngine(selectors);

    final result = engine.parse("#a && )");

    expect(result.selectorMatches, hasLength(1));
    expect(result.issues, isNotEmpty);
    expect(
      result.issues.any((issue) => issue.severity == QuerySeverity.warning),
      isTrue,
    );
  });
}
