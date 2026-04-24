import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/logic/search/query/query.dart";

import "query_test_harness.dart";

void main() {
  final selectors = selectorsTagOnly();

  test("respects NOT, AND, OR precedence", () {
    checkQuery(
      "NOT #a OR #b AND #c",
      selectors: selectors,
    ).expectNoIssues().expectNoQuery().expectExpression((expression) {
      final root = expression.isOr();

      root.left().isNot().inner().isSelector(id: "tag", value: "a");

      final andNode = root.right().isAnd();
      andNode.left().isSelector(id: "tag", value: "b");
      andNode.right().isSelector(id: "tag", value: "c");
      andNode.operatorRange(const QueryRange(13, 16));
    }).done();
  });

  test("inserts implicit AND between adjacent terms", () {
    checkQuery(
      "#a #b",
      selectors: selectors,
    ).expectNoIssues().expectNoQuery().expectExpression((expression) {
      final andNode = expression.isAnd();
      andNode.left().isSelector(id: "tag", value: "a");
      andNode.right().isSelector(id: "tag", value: "b");
      andNode.operatorRange(null);
    }).done();
  });

  test("parentheses group expressions", () {
    checkQuery(
      "(#a OR #b) AND #c",
      selectors: selectors,
    ).expectNoIssues().expectNoQuery().expectExpression((expression) {
      final andNode = expression.isAnd();
      final grouped = andNode.left().isOr();
      grouped.left().isSelector(id: "tag", value: "a");
      grouped.right().isSelector(id: "tag", value: "b");
      andNode.right().isSelector(id: "tag", value: "c");
    }).done();
  });

  test("word operators are case insensitive", () {
    checkQuery(
      "not #a Or #b aNd #c",
      selectors: selectors,
    ).expectNoIssues().expectNoQuery().expectExpression((expression) {
      final root = expression.isOr();
      root.left().isNot().inner().isSelector(id: "tag", value: "a");
      final andNode = root.right().isAnd();
      andNode.left().isSelector(id: "tag", value: "b");
      andNode.right().isSelector(id: "tag", value: "c");
    }).done();
  });

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
