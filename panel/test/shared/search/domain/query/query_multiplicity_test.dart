import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  test(
    "a repeated single selector keeps both matches and marks the second",
    () {
      final result =
          checkQuery(
                "id:1 id:2",
                selectors: [
                  const KeyValueSelectorDefinition(
                    id: "id",
                    key: "id:",
                    multiplicity: QueryMultiplicity.single,
                  ),
                ],
              )
              .expectIssues([QueryIssueCode.multiplicityViolation])
              .expectNoQuery()
              .expectExpression((token) {
                final and = token.isAnd();
                and.left().isSelector(id: "id", value: "1");
                and.right().isSelector(id: "id", value: "2");
              })
              .done();

      expect(result.selectors, hasLength(2));
      expect(result.selectors.first.range.start, 0);
      expect(result.selectors.first.range.end, 4);
      expect(result.selectors.last.range.start, 5);
      expect(result.selectors.last.range.end, 9);
      final issue = result.issues.single;
      expect(issue.code, QueryIssueCode.multiplicityViolation);
      expect(issue.severity, QuerySeverity.error);
      expect(issue.message, "Selector id can only appear once");
      expect(issue.range, const QueryRange(5, 9));
    },
  );
}
