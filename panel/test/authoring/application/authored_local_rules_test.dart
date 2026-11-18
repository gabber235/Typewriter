import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  test("nested named fields use the rule subject representation", () {
    final fixture = AuthoredDraft.nestedRule();

    final projection = AuthoredRuleProjection.evaluate(
      draft: fixture.draft,
      catalog: fixture.catalog,
      resource: fixture.resource,
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
    );

    final finding = projection.checks.single.findings.single;
    expect(finding.code, "positive");
    expect(
      finding.origin,
      fixture.catalog.snapshot.configuration.single.origin,
    );
    expect(finding.related, isEmpty);
    expect(
      finding.primary,
      skir.ValueLocation(
        resource: fixture.resource,
        path: skir.ValuePath(
          segments: [
            skir.PathSegment.createField(name: "placement"),
            skir.PathSegment.createField(name: "width"),
          ],
        ),
      ),
    );
  });

  test("collection patterns use each expanded item field representation", () {
    final fixture = AuthoredDraft.nestedRule(collection: true);

    final projection = AuthoredRuleProjection.evaluate(
      draft: fixture.draft,
      catalog: fixture.catalog,
      resource: fixture.resource,
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
    );

    expect([
      for (final check in projection.checks) check.outcome,
    ], everyElement(skir.CheckOutcome.finished));
    final finding = projection.checks.expand((check) => check.findings).single;
    expect(finding.code, "positive");
    expect(finding.related, isEmpty);
    expect(finding.primary!.path.segments, [
      skir.PathSegment.createField(name: "placements"),
      skir.PathSegment.createItem(id: skir.ItemId(value: "first")),
      skir.PathSegment.createField(name: "width"),
    ]);
  });

  test(
    "an explicit target on another field resolves from the nested owner",
    () {
      final fixture = AuthoredDraft.nestedRule(
        targets: [
          skir.RelativeFieldPattern(
            segments: [skir.FieldPatternSegment.createField(name: "height")],
          ),
        ],
      );
      final projection = AuthoredRuleProjection.evaluate(
        draft: fixture.draft,
        catalog: fixture.catalog,
        resource: fixture.resource,
        budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
      );

      final finding = projection.checks.single.findings.single;
      expect(
        finding.primary,
        skir.ValueLocation(
          resource: fixture.resource,
          path: editorRootPath.field("placement").field("height"),
        ),
      );
      expect(finding.related, isEmpty);
    },
  );

  test("a rule that needs type facts evaluates against the catalog", () {
    // The subject is an int32, so a rule requiring text fails it; without
    // the catalog's type facts the rule could not run at all.
    final fixture = AuthoredDraft.nestedRule(
      predicate: portableCall(
        "value.instance_of",
        [
          skir.ExpressionNode.createInput(
            binding: configuredValueBindingId,
            path: editorRootPath,
          ),
        ],
        typeArguments: [skir.TypeTemplate.wrapScalar(skir.ScalarKind.text)],
      ),
    );
    final projection = AuthoredRuleProjection.evaluate(
      draft: fixture.draft,
      catalog: fixture.catalog,
      resource: fixture.resource,
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
    );

    final check = projection.checks.single;
    expect(check.outcome, skir.CheckOutcome.finished);
    expect(check.findings.single.code, "positive");
  });

  test("a rule without explicit targets remains on its matched subject", () {
    final fixture = AuthoredDraft.nestedRule(targets: const []);
    final projection = AuthoredRuleProjection.evaluate(
      draft: fixture.draft,
      catalog: fixture.catalog,
      resource: fixture.resource,
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
    );

    final finding = projection.checks.single.findings.single;
    expect(
      finding.primary,
      skir.ValueLocation(
        resource: fixture.resource,
        path: editorRootPath.field("placement").field("width"),
      ),
    );
    expect(finding.related, isEmpty);
  });
  test("a resource of unknown type reports its pending type and still checks "
      "its fields", () {
    final fixture = AuthoredDraft.nestedRule();
    final record = fixture.draft.resource(fixture.resource)!;
    final observation = AuthoringDocument(
      catalog: fixture.catalog,
      entries: {
        fixture.resource: skir.AuthoringResource(
          id: fixture.resource,
          content: skir.AuthoringRecord(
            types: const [],
            configuration: skir.TypeSelection.defaultInstance,
            fields: record.fields,
          ),
        ),
      },
      links: const [],
    );
    final host = bareWorkspaceHost(fixture.resource, observation);
    final document = host.document;
    expect(
      document.diagnostics
          .where((finding) => finding.code == "pending_type")
          .single
          .targets,
      [
        PortableDiagnosticTarget.value(
          skir.ValueLocation(resource: fixture.resource, path: editorRootPath),
        ),
      ],
    );
    expect(
      document.diagnostics
          .where((finding) => finding.code == "positive")
          .single
          .targets,
      [
        PortableDiagnosticTarget.value(
          skir.ValueLocation(
            resource: fixture.resource,
            path: editorRootPath.field("placement").field("width"),
          ),
        ),
      ],
    );
  });

  test("an initialization finding shows at its field as a warning beside "
      "the resource's rule findings", () {
    final fixture = AuthoredDraft.nestedRule();
    final observation = AuthoringDocument(
      catalog: fixture.catalog,
      entries: {
        fixture.resource: skir.AuthoringResource(
          id: fixture.resource,
          content: fixture.draft.resource(fixture.resource)!,
        ),
      },
      links: const [],
      initializationFindings: [
        LocatedInitializationFinding(
          location: skir.ValueLocation(
            resource: fixture.resource,
            path: editorRootPath.field("otherResourceField"),
          ),
          evidence: skir.DiagnosticEvidence(
            catalog: fixture.draft.generation,
            evidence: [
              skir.CheckEvidence.wrapFact(
                skir.EditExpectation.createResource(
                  id: fixture.resource,
                  expected: fixture.draft.resource(fixture.resource),
                ),
              ),
            ],
          ),
          diagnostic: skir.InitializationDiagnostic(
            field: null,
            code: "initialization_pending",
            message: "A default could not be prepared",
            relativePath: editorRootPath.field("otherResourceField"),
          ),
        ),
      ],
    );
    final host = bareWorkspaceHost(fixture.resource, observation);
    final document = host.document;
    final initialization = document.diagnostics.singleWhere(
      (finding) => finding.code == "initialization_pending",
    );
    expect(initialization.message, "A default could not be prepared");
    expect(initialization.targets, [
      PortableDiagnosticTarget.value(
        skir.ValueLocation(
          resource: fixture.resource,
          path: editorRootPath.field("otherResourceField"),
        ),
      ),
    ]);
    expect(initialization.severity, skir.DiagnosticSeverity.warning);
    expect(
      document.diagnostics
          .singleWhere((finding) => finding.code == "positive")
          .targets,
      [
        PortableDiagnosticTarget.value(
          skir.ValueLocation(
            resource: fixture.resource,
            path: editorRootPath.field("placement").field("width"),
          ),
        ),
      ],
    );
  });
}
