import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  const selectors = <QuerySelectorDefinition>[
    KeyValueSelectorDefinition(
      id: "book",
      key: "book:",
      value: QuerySelectorValue.sourceBacked(),
    ),
    KeyValueSelectorDefinition(
      id: "page",
      key: "page:",
      value: QuerySelectorValue.sourceBacked(),
    ),
    KeyValueSelectorDefinition(
      id: "tag",
      key: "tag:",
      value: QuerySelectorValue.sourceBacked(),
    ),
  ];

  test("OR sibling does not constrain completion in active branch", () {
    final raw = "book:a OR (tag:x AND page:)";
    final result = Query(selectors).parse(raw, cursorOffset: raw.length - 1);

    final request = result.completionRequest(selectors);

    expect(request?.selectorId, "page");
    expect(request?.partial, "");
    expect(
      request?.scope,
      const SearchSelectorExpression.leaf(
        SearchParsedSelector(selectorId: "tag", key: "tag:", value: "x"),
      ),
    );
  });

  test("negated AND sibling constrains completion", () {
    final raw = "!book:a AND page:";
    final result = Query(selectors).parse(raw, cursorOffset: raw.length);

    final request = result.completionRequest(selectors);

    expect(
      request?.scope,
      const SearchSelectorExpression.not(
        SearchSelectorExpression.leaf(
          SearchParsedSelector(selectorId: "book", key: "book:", value: "a"),
        ),
      ),
    );
  });

  test("free text cannot be an operand of selector OR", () {
    final result = Query(selectors).parse("page:intro OR dragon");

    expect(
      result.issues.map((issue) => issue.code),
      contains(QueryIssueCode.unexpectedToken),
    );
  });
}
