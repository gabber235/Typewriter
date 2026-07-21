import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "support/query_test_harness.dart";

void main() {
  final selectors = selectorsTagAndTitle();

  test("NOT binds tighter than AND binds tighter than OR", () {
    checkQuery(
      "NOT #a OR #b AND #c",
      selectors: selectors,
    ).expectNoIssues().expectNoQuery().expectExpression((expression) {
      final orNode = expression.isOr();
      orNode.left().isNot().inner().isSelector(id: "tag", value: "a");
      final andNode = orNode.right().isAnd();
      andNode.left().isSelector(id: "tag", value: "b");
      andNode.right().isSelector(id: "tag", value: "c");
    }).done();
  });

  test("AND binds tighter than OR", () {
    checkQuery(
      "#a OR #b AND #c",
      selectors: selectors,
    ).expectNoIssues().expectNoQuery().expectExpression((expression) {
      final orNode = expression.isOr();
      orNode.left().isSelector(id: "tag", value: "a");
      final andNode = orNode.right().isAnd();
      andNode.left().isSelector(id: "tag", value: "b");
      andNode.right().isSelector(id: "tag", value: "c");
    }).done();
  });

  test("parentheses override precedence", () {
    checkQuery(
      "(#a OR #b) AND #c",
      selectors: selectors,
    ).expectNoIssues().expectNoQuery().expectExpression((expression) {
      final andNode = expression.isAnd();
      final orNode = andNode.left().isOr();
      orNode.left().isSelector(id: "tag", value: "a");
      orNode.right().isSelector(id: "tag", value: "b");
      andNode.right().isSelector(id: "tag", value: "c");
    }).done();
  });

  test("double negation", () {
    checkQuery(
      "NOT NOT #a",
      selectors: selectors,
    ).expectNoIssues().expectNoQuery().expectExpression((expression) {
      expression.isNot().inner().isNot().inner().isSelector(
        id: "tag",
        value: "a",
      );
    }).done();
  });

  test("NOT on parenthesized group", () {
    checkQuery(
      "NOT (#a OR #b)",
      selectors: selectors,
    ).expectNoIssues().expectNoQuery().expectExpression((expression) {
      final notNode = expression.isNot();
      final orNode = notNode.inner().isOr();
      orNode.left().isSelector(id: "tag", value: "a");
      orNode.right().isSelector(id: "tag", value: "b");
    }).done();
  });

  test("deep nesting preserves structure", () {
    checkQuery(
      "(#a AND #b) OR (#c AND #d)",
      selectors: selectors,
    ).expectNoIssues().expectNoQuery().expectExpression((expression) {
      final orNode = expression.isOr();
      final leftAnd = orNode.left().isAnd();
      leftAnd.left().isSelector(id: "tag", value: "a");
      leftAnd.right().isSelector(id: "tag", value: "b");
      final rightAnd = orNode.right().isAnd();
      rightAnd.left().isSelector(id: "tag", value: "c");
      rightAnd.right().isSelector(id: "tag", value: "d");
    }).done();
  });

  test("single term produces term node", () {
    checkQuery(
      "#a",
      selectors: selectors,
    ).expectNoIssues().expectNoQuery().expectExpression((expression) {
      expression
          .range(const QueryRange(0, 2))
          .isSelector(id: "tag", value: "a");
    }).done();
  });

  test("term node range matches source", () {
    checkQuery(
      "#a",
      selectors: selectors,
    ).expectNoIssues().expectNoQuery().expectExpression((expression) {
      expression
          .range(const QueryRange(0, 2))
          .isSelector(id: "tag", value: "a");
    }).done();
  });

  test("AND node range spans both operands", () {
    checkQuery(
      "#a AND #b",
      selectors: selectors,
    ).expectNoIssues().expectNoQuery().expectExpression((expression) {
      final andNode = expression.range(const QueryRange(0, 9)).isAnd();
      andNode.left().isSelector(id: "tag", value: "a");
      andNode.right().isSelector(id: "tag", value: "b");
    }).done();
  });

  test("NOT node range spans operator to operand end", () {
    checkQuery(
      "NOT #a",
      selectors: selectors,
    ).expectNoIssues().expectNoQuery().expectExpression((expression) {
      expression
          .range(const QueryRange(0, 6))
          .isNot()
          .inner()
          .isSelector(id: "tag", value: "a");
    }).done();
  });

  test("OR node range spans both operands", () {
    checkQuery(
      "#a OR #b",
      selectors: selectors,
    ).expectNoIssues().expectNoQuery().expectExpression((expression) {
      final orNode = expression.range(const QueryRange(0, 8)).isOr();
      orNode.left().isSelector(id: "tag", value: "a");
      orNode.right().isSelector(id: "tag", value: "b");
    }).done();
  });

  test("parenthesized group range covers full parens", () {
    checkQuery(
      "(#a)",
      selectors: selectors,
    ).expectNoIssues().expectNoQuery().expectExpression((expression) {
      expression
          .range(const QueryRange(1, 3))
          .isSelector(id: "tag", value: "a");
    }).done();
  });

  test("mixed operators all caps", () {
    checkQuery(
      "NOT #a AND #b OR #c",
      selectors: selectors,
    ).expectNoIssues().expectNoQuery().expectExpression((expression) {
      final orNode = expression.isOr();
      final andNode = orNode.left().isAnd();
      andNode.left().isNot().inner().isSelector(id: "tag", value: "a");
      andNode.right().isSelector(id: "tag", value: "b");
      orNode.right().isSelector(id: "tag", value: "c");
    }).done();
  });

  test("symbolic and word mixed", () {
    checkQuery(
      "!#a AND #b || #c",
      selectors: selectors,
    ).expectNoIssues().expectNoQuery().expectExpression((expression) {
      final orNode = expression.isOr();
      final andNode = orNode.left().isAnd();
      andNode.left().isNot().inner().isSelector(id: "tag", value: "a");
      andNode.right().isSelector(id: "tag", value: "b");
      orNode.right().isSelector(id: "tag", value: "c");
    }).done();
  });
}
