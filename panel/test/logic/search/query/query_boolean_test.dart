import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/logic/search/query/query.dart";

void main() {
  final selectors = <QuerySelectorDefinition>[
    const SymbolSelectorDefinition(id: "tag", symbol: "#"),
  ];

  test("respects NOT, AND, OR precedence", () {
    final engine = QueryEngine(selectors);

    final result = engine.parse("NOT #a OR #b AND #c");

    expect(result.expression, isA<QueryOrNode>());
    final root = result.expression! as QueryOrNode;
    expect(root.left, isA<QueryNotNode>());
    expect(root.right, isA<QueryAndNode>());

    final andNode = root.right as QueryAndNode;
    expect(andNode.implicit, isFalse);
  });

  test("inserts implicit AND between adjacent terms", () {
    final engine = QueryEngine(selectors);

    final result = engine.parse("#a #b");

    expect(result.expression, isA<QueryAndNode>());
    final andNode = result.expression! as QueryAndNode;
    expect(andNode.implicit, isTrue);
  });

  test("parentheses group expressions", () {
    final engine = QueryEngine(selectors);

    final result = engine.parse("(#a OR #b) AND #c");

    expect(result.expression, isA<QueryAndNode>());
    final andNode = result.expression! as QueryAndNode;
    expect(andNode.left, isA<QueryOrNode>());
    final grouped = andNode.left as QueryOrNode;
    expect(grouped.range.start, 0);
    expect(grouped.range.end, 10);
  });

  test("word operators are case insensitive", () {
    final engine = QueryEngine(selectors);

    final result = engine.parse("not #a Or #b aNd #c");

    expect(result.expression, isA<QueryOrNode>());
  });

  test("symbolic operators are supported", () {
    final engine = QueryEngine(selectors);

    final result = engine.parse("!#a || #b && #c");

    expect(result.expression, isA<QueryOrNode>());
  });
}
