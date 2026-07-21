import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "support/query_test_harness.dart";

void main() {
  test("case insensitive selector matches mixed case", () {
    checkQuery(
      "Title:\"A\"",
      selectors: [const KeyValueSelectorDefinition(id: "title", key: "title:")],
    ).expectNoIssues().expectNoQuery().expectExpression((expression) {
      expression.isSelector(id: "title", value: "A");
    }).done();
  });

  test("case sensitive selector requires exact case", () {
    checkQuery(
      "Title:\"A\"",
      selectors: [
        const KeyValueSelectorDefinition(
          id: "title",
          key: "title:",
          caseSensitive: true,
        ),
      ],
    ).expectNoIssues().expectQuery("Title:\"A\"").expectNoExpression().done();

    checkQuery(
      "title:\"A\"",
      selectors: [
        const KeyValueSelectorDefinition(
          id: "title",
          key: "title:",
          caseSensitive: true,
        ),
      ],
    ).expectNoIssues().expectNoQuery().expectExpression((expression) {
      expression.isSelector(id: "title", value: "A");
    }).done();
  });

  test("operators remain case insensitive", () {
    checkQuery(
      "nOt #a aNd #b oR #c",
      selectors: selectorsTagOnly(),
    ).expectNoIssues().expectNoQuery().expectExpression((expression) {
      final root = expression.isOr();
      final andNode = root.left().isAnd();
      andNode.left().isNot().inner().isSelector(id: "tag", value: "a");
      andNode.right().isSelector(id: "tag", value: "b");
      root.right().isSelector(id: "tag", value: "c");
    }).done();
  });

  test("mixed symbolic and word operators remain supported", () {
    checkQuery(
      "!#a Or #b && #c",
      selectors: selectorsTagOnly(),
    ).expectNoIssues().expectNoQuery().expectExpression((expression) {
      final root = expression.isOr();
      root.left().isNot().inner().isSelector(id: "tag", value: "a");
      final andNode = root.right().isAnd();
      andNode.left().isSelector(id: "tag", value: "b");
      andNode.right().isSelector(id: "tag", value: "c");
    }).done();
  });
}
