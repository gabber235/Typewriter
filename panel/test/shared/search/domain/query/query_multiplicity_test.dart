import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "support/query_test_harness.dart";

void main() {
  test("keeps all repeated single selector matches and reports error", () {
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
    expect(
      result.issues.any(
        (issue) =>
            issue.code == QueryIssueCode.multiplicityViolation &&
            issue.severity == QuerySeverity.error,
      ),
      isTrue,
    );
  });
}
