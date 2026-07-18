import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/shared/search/domain/query/query.dart";

import "support/query_test_harness.dart";

void main() {
  final selectors = selectorsTagAndTitle();

  test("no implicit AND given explicit operator", () {
    checkQuery(
      "#a AND #b",
      selectors: selectors,
    ).expectNoIssues().expectNoQuery().expectExpression((expression) {
      final andNode = expression.isAnd();
      andNode.left().isSelector(id: "tag", value: "a");
      andNode.right().isSelector(id: "tag", value: "b");
      andNode.operatorRange(const QueryRange(3, 6));
    }).done();
  });

  test("implicit AND between two term tokens", () {
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

  test("group before selector still creates implicit AND", () {
    checkQuery(
      "(#a) #b",
      selectors: selectors,
    ).expectNoIssues().expectNoQuery().expectExpression((expression) {
      final andNode = expression.isAnd();
      andNode.left().isSelector(id: "tag", value: "a");
      andNode.right().isSelector(id: "tag", value: "b");
      andNode.operatorRange(null);
    }).done();
  });

  test("implicit AND before open paren after term", () {
    checkQuery(
      "#a (#b)",
      selectors: selectors,
    ).expectNoIssues().expectNoQuery().expectExpression((expression) {
      final andNode = expression.isAnd();
      andNode.left().isSelector(id: "tag", value: "a");
      andNode.right().isSelector(id: "tag", value: "b");
      andNode.operatorRange(null);
    }).done();
  });

  test("implicit AND between NOT and selector", () {
    checkQuery(
      "(#a) NOT #b",
      selectors: selectors,
    ).expectNoIssues().expectNoQuery().expectExpression((expression) {
      final andNode = expression.isAnd();
      andNode.left().isSelector(id: "tag", value: "a");
      andNode.right().isNot().inner().isSelector(id: "tag", value: "b");
      andNode.operatorRange(null);
    }).done();
  });

  test("no implicit AND given operators", () {
    checkQuery(
      "#a AND #b OR #c",
      selectors: selectors,
    ).expectNoIssues().expectNoQuery().expectExpression((expression) {
      final orNode = expression.isOr();
      final andNode = orNode.left().isAnd();
      andNode.left().isSelector(id: "tag", value: "a");
      andNode.right().isSelector(id: "tag", value: "b");
      orNode.right().isSelector(id: "tag", value: "c");
    }).done();
  });

  test("no implicit AND between two operators", () {
    checkQuery(
      "AND OR",
      selectors: selectors,
    ).expectNoIssues().expectQuery("AND OR").expectNoExpression().done();
  });

  test("no implicit AND between operator and open paren", () {
    checkQuery(
      "AND (#b)",
      selectors: selectors,
    ).expectNoIssues().expectQuery("AND").expectExpression((expression) {
      expression.isSelector(id: "tag", value: "b");
    }).done();
  });

  test("no implicit AND with leftover text before selector", () {
    checkQuery(
      "hello #a",
      selectors: selectors,
    ).expectNoIssues().expectQuery("hello").expectExpression((expression) {
      expression.isSelector(id: "tag", value: "a");
    }).done();
  });

  test("empty token list returns empty", () {
    checkQuery(
      "",
      selectors: selectors,
    ).expectNoIssues().expectNoQuery().expectNoExpression().done();
  });

  test("single token returns single term", () {
    checkQuery(
      "#a",
      selectors: selectors,
    ).expectNoIssues().expectNoQuery().expectExpression((expression) {
      expression.isSelector(id: "tag", value: "a");
    }).done();
  });
}
