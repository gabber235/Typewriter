import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/logic/search/query/query.dart";

void main() {
  final selectors = <QuerySelectorDefinition>[
    const SymbolSelectorDefinition(id: "tag", symbol: "#"),
    const KeyValueSelectorDefinition(id: "title", key: "title"),
  ];

  test("extracts symbol and key value selectors with spans", () {
    final engine = QueryEngine(selectors);

    final result = engine.parse("#tag title:\"My title\" hello");

    expect(result.selectorMatches, hasLength(2));
    expect(result.textTerms, hasLength(1));
    expect(result.leftoverText, "hello");

    final first = result.selectorMatches.first;
    expect(first, isA<SymbolSelectorMatch>());
    final symbolMatch = first as SymbolSelectorMatch;
    expect(symbolMatch.symbol, "#");
    expect(symbolMatch.token, "tag");
    expect(symbolMatch.fullRange.start, 0);
    expect(symbolMatch.fullRange.end, 4);
    expect(symbolMatch.symbolRange.start, 0);
    expect(symbolMatch.symbolRange.end, 1);
    expect(symbolMatch.tokenRange.start, 1);
    expect(symbolMatch.tokenRange.end, 4);

    final second = result.selectorMatches.last;
    expect(second, isA<KeyValueSelectorMatch>());
    final keyValue = second as KeyValueSelectorMatch;
    expect(keyValue.key, "title");
    expect(keyValue.value, "My title");
    expect(keyValue.fullRange.start, 5);
    expect(keyValue.fullRange.end, 21);
    expect(keyValue.keyRange.start, 5);
    expect(keyValue.keyRange.end, 10);
    expect(keyValue.valueRange?.start, 12);
    expect(keyValue.valueRange?.end, 20);
    expect(keyValue.quoteRange?.start, 11);
    expect(keyValue.quoteRange?.end, 21);

    final textTerm = result.textTerms.single;
    expect(textTerm.text, "hello");
    expect(textTerm.range.start, 22);
    expect(textTerm.range.end, 27);
  });

  test("extracts unquoted key value selectors", () {
    final engine = QueryEngine(selectors);

    final result = engine.parse("title:World hello");

    expect(result.selectorMatches, hasLength(1));
    final match = result.selectorMatches.single as KeyValueSelectorMatch;
    expect(match.key, "title");
    expect(match.value, "World");
    expect(match.valueRange?.start, 6);
    expect(match.valueRange?.end, 11);
    expect(result.leftoverText, "hello");
  });

  test("reports unclosed quote as warning and keeps best effort value", () {
    final engine = QueryEngine(selectors);

    final result = engine.parse("title:\"My title hello");

    expect(result.selectorMatches, hasLength(1));
    final match = result.selectorMatches.single as KeyValueSelectorMatch;
    expect(match.value, "My title hello");

    expect(result.issues, hasLength(1));
    final issue = result.issues.single;
    expect(issue.code, QueryIssueCode.unclosedQuote);
    expect(issue.severity, QuerySeverity.warning);
    expect(issue.range, isNotNull);
  });
}
