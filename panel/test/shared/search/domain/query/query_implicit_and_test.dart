import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

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

  // Found by query_properties_test: inside parentheses adjacent selectors
  // fell back to free text, so "(#a #b) AND #c" dropped "#c" from the search.
  test("adjacent terms inside parentheses form an implicit AND", () {
    checkQuery(
      "(#a #b) AND #c",
      selectors: selectors,
    ).expectNoIssues().expectNoQuery().expectExpression((expression) {
      final and = expression.isAnd()..operatorRange(const QueryRange(8, 11));
      final implicit = and.left().isAnd()..operatorRange(null);
      implicit.left().isSelector(id: "tag", value: "a");
      implicit.right().isSelector(id: "tag", value: "b");
      and.right().isSelector(id: "tag", value: "c");
    }).done();
  });

  test("implicit AND binds looser than OR", () {
    checkQuery(
      "#a #b || #c",
      selectors: selectors,
    ).expectNoIssues().expectNoQuery().expectExpression((expression) {
      final implicit = expression.isAnd()..operatorRange(null);
      implicit.left().isSelector(id: "tag", value: "a");
      final or = implicit.right().isOr();
      or.left().isSelector(id: "tag", value: "b");
      or.right().isSelector(id: "tag", value: "c");
    }).done();
  });
}
