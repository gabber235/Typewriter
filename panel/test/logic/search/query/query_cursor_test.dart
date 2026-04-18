import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/logic/search/query/query.dart";

void main() {
  final selectors = <QuerySelectorDefinition>[
    const SymbolSelectorDefinition(id: "tag", symbol: "#"),
    const KeyValueSelectorDefinition(id: "role", key: "role"),
  ];

  test("cursor inside value resolves selector value context", () {
    final engine = QueryEngine(selectors);

    final result = engine.parse("role:ad", cursorOffset: 7);

    expect(result.cursorContext, isA<SelectorValueCursorContext>());
    final context = result.cursorContext! as SelectorValueCursorContext;
    expect(context.selectorId, "role");
    expect(context.partialValue, "ad");
  });

  test("cursor inside key resolves selector key context", () {
    final engine = QueryEngine(selectors);

    final result = engine.parse("role:ad", cursorOffset: 2);

    expect(result.cursorContext, isA<SelectorKeyCursorContext>());
    final context = result.cursorContext! as SelectorKeyCursorContext;
    expect(context.partialKey, "ro");
  });

  test("cursor on operator resolves operator context", () {
    final engine = QueryEngine(selectors);

    final result = engine.parse("#a AND #b", cursorOffset: 4);

    expect(result.cursorContext, isA<OperatorCursorContext>());
    final context = result.cursorContext! as OperatorCursorContext;
    expect(context.partialOperator.toLowerCase(), "a");
  });

  test("cursor in plain term resolves text context", () {
    final engine = QueryEngine(selectors);

    final result = engine.parse("hello #a", cursorOffset: 2);

    expect(result.cursorContext, isA<TextTermCursorContext>());
    final context = result.cursorContext! as TextTermCursorContext;
    expect(context.partialText, "he");
  });

  test("cursor outside known ranges resolves unknown context", () {
    final engine = QueryEngine(selectors);

    final result = engine.parse("#a  #b", cursorOffset: 3);

    expect(result.cursorContext, isA<UnknownCursorContext>());
  });
}
