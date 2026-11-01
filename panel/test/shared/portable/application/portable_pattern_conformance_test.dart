import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
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
      test("expands $id as Realm does", () {
        expect(unique, isTrue, reason: "case ids are unique");
        // The owner sits at the root of the resource the fixture names.
        skir.ValueLocation owner(Map<String, Object?> fixture) =>
            skir.ValueLocation(
              resource: skir.ResourceId(value: fixture["owner"]! as String),
              path: editorRootPath,
            );
        skir.RelativeFieldPattern pattern(Object? json) =>
            skir.RelativeFieldPattern.serializer.fromJson(json);
        expectFixtureKeys(fixture, {
          "id",
          "value",
          "owner",
          "pattern",
          "expected",
        }, "expansion");
        final location = owner(fixture);
        final locations = fixtureValue(
          fixture["value"]! as Map<String, Object?>,
        ).expandPattern(location, pattern(fixture["pattern"]));
        expect(locations.map(fixtureLocation), fixture["expected"]);
      });
    }
  });
  group("rules", () {
    for (final fixture
        in (document["rules"]! as List<Object?>).cast<Map<String, Object?>>()) {
      final id = fixture["id"]! as String;
      final unique = ids.add(id);
      test("projects $id as Realm does", () {
        expect(unique, isTrue, reason: "case ids are unique");
        // The owner sits at the root of the resource the fixture names.
        skir.ValueLocation owner(Map<String, Object?> fixture) =>
            skir.ValueLocation(
              resource: skir.ResourceId(value: fixture["owner"]! as String),
              path: editorRootPath,
            );
        skir.RelativeFieldPattern pattern(Object? json) =>
            skir.RelativeFieldPattern.serializer.fromJson(json);
        // A check in the fixture's compact form. Diagnostic ids and origins
        // are host specific and not compared.
        Map<String, Object?> compactCheck(AuthoredRuleCheck check) => {
          "subject": fixtureLocation(check.subject),
          "outcome": switch (check.outcome) {
            skir.CheckOutcome_needsInputWrapper(:final value) => {
              "needs_input": value.map(fixtureLocation).toList(),
            },
            skir.CheckOutcome_failedWrapper(:final value) => {
              "failed": {
                "failure": value.single.code,
                "primary": fixtureLocation(value.single.primary!),
                "related": value.single.related.map(fixtureLocation).toList(),
              },
            },
            final outcome when outcome == skir.CheckOutcome.finished =>
              "finished",
            final outcome => "unexpected $outcome",
          },
          "findings": [
            for (final finding in check.findings)
              {
                "code": finding.code,
                "message": finding.message,
                "severity": skir.DiagnosticSeverity.serializer.toJson(
                  finding.severity,
                  readableFlavor: true,
                ),
                "primary": fixtureLocation(finding.primary!),
                "related": finding.related.map(fixtureLocation).toList(),
              },
          ],
        };
        expectFixtureKeys(fixture, {
          "id",
          "value",
          "owner",
          "recipe",
          "predicate",
          "diagnostic",
          "expected",
        }, "rule");
        final location = owner(fixture);
        final definition = skir.TypeDefinitionId(
          typeId: skir.TypeId.createQualified(
            namespace: "fixture",
            name: "Owner",
          ),
          revision: 1,
        );
        final rule = skir.RuleId(
          origin: skir.RuleOrigin(owner: definition, ordinal: 0),
          localIndex: 0,
        );
        final diagnostic = fixture["diagnostic"]! as Map<String, Object?>;
        expectFixtureKeys(diagnostic, {
          "code",
          "message",
          "severity",
          "targets",
        }, "diagnostic");
        final catalog = testCheckedCatalog(
          types: [declaredRecord(definition)],
          configuration: [
            skir.ConfigurationRecipe(
              origin: rule.origin,
              relativePath: pattern(fixture["recipe"]),
              representationCondition: null,
              rules: [
                skir.OwnedRule(
                  id: rule,
                  descriptor: skir.RuleDescriptor(
                    predicate: skir.ExpressionNode.serializer.fromJson(
                      fixture["predicate"],
                    ),
                  ),
                  diagnostic: skir.DiagnosticTemplate(
                    code: diagnostic["code"]! as String,
                    message: diagnostic["message"]! as String,
                    severity: skir.DiagnosticSeverity.serializer.fromJson(
                      diagnostic["severity"],
                    ),
                    targets: [
                      for (final target
                          in diagnostic["targets"]! as List<Object?>)
                        pattern(target),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
        final value = fixtureValue(fixture["value"]! as Map<String, Object?>);
        final draft = AuthoringEdit(
          generation: catalog.snapshot.generation,
          resources: [
            skir.AuthoringResource(
              id: location.resource,
              content: skir.AuthoringRecord(
                configuration: skir.TypeSelection.createComplete(
                  definition: definition,
                  arguments: const [],
                ),
                fields: value.authoredRecord!.fields,
              ),
            ),
          ],
          links: const [],
          catalog: catalog,
        );
        final projection = AuthoredRuleProjection.evaluate(
          draft: draft,
          catalog: catalog,
          resource: location.resource,
          budget: skir.EvaluationBudget(
            maxSteps: 1000,
            maxCollectionItems: 1000,
          ),
        );
        expect([
          for (final check in projection.checks) compactCheck(check),
        ], fixture["expected"]);
      });
    }
  });
}
