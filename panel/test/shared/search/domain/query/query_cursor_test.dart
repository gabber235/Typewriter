import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "support/query_test_harness.dart";

void main() {
  final selectors = <QuerySelectorDefinition>[
    const KeyValueSelectorDefinition(id: "tag", key: "#"),
    const KeyValueSelectorDefinition(id: "title", key: "title:"),
    KeyValueSelectorDefinition(
      id: "role",
      key: "role:",
      value: QuerySelectorValue.enumValue(["admin", "author", "member"]),
    ),
  ];

  test("cursor inside value resolves selector value context", () {
    final result = checkQuery("role:ad", selectors: selectors, cursorOffset: 7)
        .expectIssues([QueryIssueCode.invalidSelectorValue])
        .expectNoQuery()
        .expectExpression((token) {
          token.isSelector(id: "role", value: "ad");
        })
        .done();

    expect(result.cursorContext, isA<SelectorValueCursorContext>());
    final context = result.cursorContext! as SelectorValueCursorContext;
    expect(context.selectorId, "role");
    expect(context.partialValue, "ad");
    expect(context.activeRange.start, 5);
    expect(context.activeRange.end, 7);
  });

  test("cursor inside symbol resolves selector value context", () {
    final result = checkQuery("#a", selectors: selectors, cursorOffset: 2)
        .expectNoIssues()
        .expectNoQuery()
        .expectExpression((token) {
          token.isSelector(id: "tag", value: "a");
        })
        .done();

    expect(result.cursorContext, isA<SelectorValueCursorContext>());
    final context = result.cursorContext! as SelectorValueCursorContext;
    expect(context.selectorId, "tag");
    expect(context.partialValue, "a");
    expect(context.keyRange.start, 0);
    expect(context.keyRange.end, 1);
    expect(context.activeRange.start, 1);
    expect(context.activeRange.end, 2);
  });

  test("cursor inside value when key is qualified", () {
    final result = checkQuery("role:", selectors: selectors, cursorOffset: 5)
        .expectIssues([QueryIssueCode.missingSelectorValue])
        .expectNoQuery()
        .expectExpression((token) {
          token.isSelector(id: "role", value: null);
        })
        .done();
    expect(result.cursorContext, isA<SelectorValueCursorContext>());
    final context = result.cursorContext! as SelectorValueCursorContext;
    expect(context.selectorId, "role");
    expect(context.partialValue, "");
    expect(context.activeRange.start, 5);
    expect(context.activeRange.end, 5);
  });

  test("cursor inside key resolves selector key context", () {
    final result = checkQuery("role:ad", selectors: selectors, cursorOffset: 2)
        .expectIssues([QueryIssueCode.invalidSelectorValue])
        .expectNoQuery()
        .expectExpression((token) {
          token.isSelector(id: "role", value: "ad");
        })
        .done();

    expect(result.cursorContext, isA<SelectorKeyCursorContext>());
    final context = result.cursorContext! as SelectorKeyCursorContext;
    expect(context.partialKey, "ro");
  });

  test("cursor on operator resolves AND operator context", () {
    final result =
        checkQuery(
          "#a AND #b",
          selectors: selectors,
          cursorOffset: 4,
        ).expectNoIssues().expectNoQuery().expectExpression((token) {
          final and = token.isAnd();
          and.left().isSelector(id: "tag", value: "a");
          and.right().isSelector(id: "tag", value: "b");
        }).done();

    expect(result.cursorContext, isA<OperatorCursorContext>());
    final context = result.cursorContext! as OperatorCursorContext;
    expect(context.partialOperator.toLowerCase(), "a");
  });

  test("cursor on operator resolves OR operator context", () {
    final result = checkQuery("#a OR #b", selectors: selectors, cursorOffset: 4)
        .expectNoIssues()
        .expectNoQuery()
        .expectExpression((token) {
          final or = token.isOr();
          or.left().isSelector(id: "tag", value: "a");
          or.right().isSelector(id: "tag", value: "b");
        })
        .done();

    expect(result.cursorContext, isA<OperatorCursorContext>());
    final context = result.cursorContext! as OperatorCursorContext;
    expect(context.partialOperator.toLowerCase(), "o");
  });

  test("cursor on operator resolves NOT operator context", () {
    final result = checkQuery("NOT #b", selectors: selectors, cursorOffset: 1)
        .expectNoIssues()
        .expectNoQuery()
        .expectExpression((token) {
          final not = token.isNot();
          not.inner().isSelector(id: "tag", value: "b");
        })
        .done();

    expect(result.cursorContext, isA<OperatorCursorContext>());
    final context = result.cursorContext! as OperatorCursorContext;
    expect(context.partialOperator.toLowerCase(), "n");
  });

  test("cursor in plain term resolves unknown context", () {
    final result = checkQuery("hello #a", selectors: selectors, cursorOffset: 2)
        .expectNoIssues()
        .expectQuery("hello")
        .expectExpression((token) {
          token.isSelector(id: "tag", value: "a");
        })
        .done();

    expect(result.cursorContext, isA<UnknownCursorContext>());
    expect(result.queryBefore, "hello");
    expect(result.queryAfter, isEmpty);
  });

  test("cursor outside known ranges resolves unknown context", () {
    final result = checkQuery("#a  #b", selectors: selectors, cursorOffset: 3)
        .expectNoIssues()
        .expectNoQuery()
        .expectExpression((token) {
          final and = token.isAnd();
          and.left().isSelector(id: "tag", value: "a");
          and.right().isSelector(id: "tag", value: "b");
        })
        .done();

    expect(result.cursorContext, isA<UnknownCursorContext>());
  });

  test("cursor in plain term after selector resolves unknown after side", () {
    final result = checkQuery("#a hello", selectors: selectors, cursorOffset: 5)
        .expectNoIssues()
        .expectQuery("hello")
        .expectExpression((token) {
          token.isSelector(id: "tag", value: "a");
        })
        .done();

    expect(result.cursorContext, isA<UnknownCursorContext>());
    expect(result.queryBefore, isEmpty);
    expect(result.queryAfter, "hello");
  });

  test("cursor in plain term has active range around word", () {
    final result =
        checkQuery("hello over there", selectors: selectors, cursorOffset: 8)
            .expectNoIssues()
            .expectQuery("hello over there")
            .expectNoExpression()
            .done();

    expect(result.cursorContext, isA<UnknownCursorContext>());
    final context = result.cursorContext! as UnknownCursorContext;
    expect(result.queryBefore, "hello over there");
    expect(result.queryAfter, isEmpty);
    expect(context.cursorOffset, 8);
    expect(context.partial, "ov");
    expect(context.activeRange.start, 6);
    expect(context.activeRange.end, 10);
  });
}
