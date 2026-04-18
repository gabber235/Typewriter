import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/logic/search/query/query.dart";

void main() {
  test("keeps all repeated single selector matches and reports error", () {
    final engine = QueryEngine([
      const KeyValueSelectorDefinition(
        id: "id",
        key: "id",
        multiplicity: QueryMultiplicity.single,
      ),
    ]);

    final result = engine.parse("id:1 id:2");

    expect(result.selectorMatches, hasLength(2));
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
