import "package:flutter_test/flutter_test.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final selectors = selectorsTagOnly();

  test("symbolic operators are supported", () {
    checkQuery(
      "!#a || #b && #c",
      selectors: selectors,
    ).expectNoIssues().expectNoQuery().expectExpression((expression) {
      final root = expression.isOr();
      root.left().isNot().inner().isSelector(id: "tag", value: "a");
      final andNode = root.right().isAnd();
      andNode.left().isSelector(id: "tag", value: "b");
      andNode.right().isSelector(id: "tag", value: "c");
    }).done();
  });
}
