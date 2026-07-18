import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/shared/search/domain/query/query.dart";

import "support/query_test_harness.dart";

void main() {
  final enumSelectors = <QuerySelectorDefinition>[
    const KeyValueSelectorDefinition(
      id: "role",
      key: "role:",
      value: QuerySelectorValue.enumValue(["admin", "author", "member"]),
    ),
    const KeyValueSelectorDefinition(id: "status", key: "status:"),
  ];

  test("enumValue selector with valid value produces no issue", () {
    final result = checkQuery("role:admin", selectors: enumSelectors)
        .expectNoIssues()
        .expectNoQuery()
        .expectExpression((token) {
          token.isSelector(id: "role", value: "admin");
        })
        .done();
    expect(result.issues, isEmpty);
    expect(result.selectors, hasLength(1));
  });

  test("enumValue selector with invalid value reports warning", () {
    final result = checkQuery("role:unknown", selectors: enumSelectors)
        .expectIssues([QueryIssueCode.invalidSelectorValue])
        .expectNoQuery()
        .expectExpression((token) {
          token.isSelector(id: "role", value: "unknown");
        })
        .done();
    expect(result.issues, hasLength(1));
    final issue = result.issues.first;
    expect(issue.code, QueryIssueCode.invalidSelectorValue);
    expect(issue.severity, QuerySeverity.warning);
    expect(issue.message, contains("role"));
    expect(issue.range, isNotNull);
  });

  test("enumValue selector with null value reports missing value", () {
    final result = checkQuery("role:", selectors: enumSelectors)
        .expectIssues([QueryIssueCode.missingSelectorValue])
        .expectNoQuery()
        .expectExpression((token) {
          token.isSelector(id: "role", value: null);
        })
        .done();
    expect(result.selectors, hasLength(1));
    expect(result.issues, hasLength(1));
    expect(result.issues.first.code, QueryIssueCode.missingSelectorValue);
  });

  final textSelectors = <QuerySelectorDefinition>[
    const KeyValueSelectorDefinition(id: "title", key: "title:"),
    const KeyValueSelectorDefinition(id: "tag", key: "#"),
  ];

  test("unknown selector key in text term reports no issue", () {
    checkQuery("unknownkey:value", selectors: textSelectors)
        .expectNoIssues()
        .expectQuery("unknownkey:value")
        .expectNoExpression()
        .done();
  });

  test("known selector key in text term reports no issue", () {
    final result = checkQuery("title:mytitle", selectors: textSelectors)
        .expectNoIssues()
        .expectNoQuery()
        .expectExpression((token) {
          token.isSelector(id: "title", value: "mytitle");
        })
        .done();
    expect(result.issues, isEmpty);
  });

  test("colon at start of text term reports no issue", () {
    checkQuery(
      ":notaselector",
      selectors: textSelectors,
    ).expectNoIssues().expectQuery(":notaselector").expectNoExpression().done();
  });

  test("multiple multiplicity selector reports no issue", () {
    final result = checkQuery("#a #b #c", selectors: textSelectors)
        .expectNoIssues()
        .expectNoQuery()
        .expectExpression((token) {
          final and = token.isAnd();
          final nested = and.left().isAnd();
          nested.left().isSelector(id: "tag", value: "a");
          nested.right().isSelector(id: "tag", value: "b");
          and.right().isSelector(id: "tag", value: "c");
        })
        .done();
    expect(result.issues, isEmpty);
    expect(result.selectors, hasLength(3));
  });

  final singleMultiplicitySelectors = <QuerySelectorDefinition>[
    const KeyValueSelectorDefinition(
      id: "id",
      key: "id:",
      multiplicity: QueryMultiplicity.single,
    ),
  ];

  test("single multiplicity repeated selector reports error", () {
    final result =
        checkQuery("id:1 id:2", selectors: singleMultiplicitySelectors)
            .expectIssues([QueryIssueCode.multiplicityViolation])
            .expectNoQuery()
            .expectExpression((token) {
              final and = token.isAnd();
              and.left().isSelector(id: "id", value: "1");
              and.right().isSelector(id: "id", value: "2");
            })
            .done();
    expect(result.issues, hasLength(1));
    final issue = result.issues.first;
    expect(issue.code, QueryIssueCode.multiplicityViolation);
    expect(issue.severity, QuerySeverity.error);
    expect(issue.message, contains("id"));
    expect(issue.range, isNotNull);
  });
}
