import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  const book = SearchSelectorExpression.leaf(
    SearchParsedSelector(selectorId: "book", key: "book:", value: "a"),
  );
  const tag = SearchSelectorExpression.leaf(
    SearchParsedSelector(selectorId: "tag", key: "tag:", value: "x"),
  );

  test("OR retains the branch a source owns", () {
    const context = SearchQueryContext(
      normalizedQuery: "",
      selectors: [
        SearchParsedSelector(selectorId: "book", key: "book:", value: "a"),
        SearchParsedSelector(selectorId: "tag", key: "tag:", value: "x"),
      ],
      selectorExpression: SearchSelectorExpression.binary(
        operator: SearchSelectorOperator.or,
        left: book,
        right: tag,
      ),
    );

    final projected = context.projectFor({"book"});

    expect(projected?.selectorExpression, book);
    expect(projected?.selectors, [
      const SearchParsedSelector(selectorId: "book", key: "book:", value: "a"),
    ]);
  });

  test("AND rejects a source that cannot satisfy every branch", () {
    const context = SearchQueryContext(
      normalizedQuery: "",
      selectors: [
        SearchParsedSelector(selectorId: "book", key: "book:", value: "a"),
        SearchParsedSelector(selectorId: "tag", key: "tag:", value: "x"),
      ],
      selectorExpression: SearchSelectorExpression.binary(
        operator: SearchSelectorOperator.and,
        left: book,
        right: tag,
      ),
    );

    expect(context.projectFor({"book"}), isNull);
  });

  test("negating an unsupported selector leaves a source eligible", () {
    const context = SearchQueryContext(
      normalizedQuery: "dragon",
      selectors: [
        SearchParsedSelector(selectorId: "book", key: "book:", value: "a"),
      ],
      selectorExpression: SearchSelectorExpression.not(book),
    );

    final projected = context.projectFor(const {});

    expect(projected, isNotNull);
    expect(projected?.selectorExpression, isNull);
    expect(projected?.normalizedQuery, "dragon");
  });
}
