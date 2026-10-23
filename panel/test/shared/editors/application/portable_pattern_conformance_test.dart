import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/catalog_fixture.dart";
import "../../../support/portable_fixture.dart";

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
        expectFixtureKeys(fixture, {
          "id",
          "value",
          "owner",
          "pattern",
          "expected",
        }, "expansion");
        final owner = _owner(fixture);
        final locations = fixtureValue(
          fixture["value"]! as Map<String, Object?>,
        ).expandPattern(owner, _pattern(fixture["pattern"]));
        expect(locations.map(fixtureLocation), fixture["expected"]);
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
        _runRule(fixture);
      });
    }
  });
}

void _runRule(Map<String, Object?> fixture) {
  expectFixtureKeys(fixture, {
    "id",
    "value",
    "owner",
    "recipe",
    "predicate",
    "diagnostic",
    "expected",
  }, "rule");
  final owner = _owner(fixture);
  final definition = skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(namespace: "fixture", name: "Owner"),
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
    types: [
      skir.PublishedType(
        searchKey: null,
        placementField: null,
        display: defaultTypeDisplay(""),
        definition: skir.TypeDefinition(
          id: definition,
          parameters: const [],
          representation: skir.RepresentationTemplate.createRecord(
            fields: const [],
            abstract_: false,
          ),
          parents: const [],
        ),
        status: skir.DeclarationStatus.ready,
        effectiveFields: const [],
        ancestorTemplates: const [],
      ),
    ],
    configuration: [
      skir.ConfigurationRecipe(
        origin: rule.origin,
        relativePath: _pattern(fixture["recipe"]),
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
                for (final target in diagnostic["targets"]! as List<Object?>)
                  _pattern(target),
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
        id: owner.resource,
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
    resource: owner.resource,
    budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 1000),
  );
  expect([
    for (final check in projection.checks) _compactCheck(check),
  ], fixture["expected"]);
}

/// The owner sits at the root of the resource the fixture names.
skir.ValueLocation _owner(Map<String, Object?> fixture) => skir.ValueLocation(
  resource: skir.ResourceId(value: fixture["owner"]! as String),
  path: editorRootPath,
);

skir.RelativeFieldPattern _pattern(Object? json) =>
    skir.RelativeFieldPattern.serializer.fromJson(json);

/// A check in the fixture's compact form. Diagnostic ids and origins are host
/// specific and not compared.
Map<String, Object?> _compactCheck(AuthoredRuleCheck check) => {
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
    final outcome when outcome == skir.CheckOutcome.finished => "finished",
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
