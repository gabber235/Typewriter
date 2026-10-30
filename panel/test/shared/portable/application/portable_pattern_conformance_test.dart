import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

/// Runs the shared pattern fixture
/// (`skir-src/editor/v1/fixtures/portable_pattern_conformance.json`, format
/// in `operations/README.md` there): expansions through [PortablePatternExpansion]
/// and rule outcomes through [AuthoredRuleProjection], both with Realm's
/// semantics.
void main() {
  final document = jsonDecode(
    File("../skir-src/editor/v1/fixtures/portable_pattern_conformance.json")
        .readAsStringSync(),
  ) as Map<String, Object?>;
  final ids = <String>{};

  test("holds only expansions and rules", () {
    expect(document.keys, ["expansions", "rules"]);
  });
  group("expansions", () {
    for (final fixture
        in (document["expansions"]! as List<Object?>)
            .cast<Map<String, Object?>>()) {
      final id = fixture["id"]! as String;
      final unique = ids.add(id);
      test(id, () {
        expect(unique, isTrue, reason: "case ids are unique");
        runPatternExpansionFixtureCase(fixture);
      });
    }
  });
  group("rules", () {
    for (final fixture
        in (document["rules"]! as List<Object?>).cast<Map<String, Object?>>()) {
      final id = fixture["id"]! as String;
      final unique = ids.add(id);
      test(id, () {
        expect(unique, isTrue, reason: "case ids are unique");
        runPatternRuleFixtureCase(fixture);
      });
    }
  });
}
