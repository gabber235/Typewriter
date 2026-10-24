import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

void main() {
  final id = skir.ResourceId(value: "book:issues");
  final at = skir.ValueLocation(
    resource: id,
    path: skir.ValuePath(
      segments: [skir.PathSegment.createField(name: "title")],
    ),
  );
  final base = fixtureAuthoringDocument(
    realm: true,
    books: [
      Book(
        bookId: id,
        title: "Harbor",
        icon: "mdi:book",
        color: Colors.blue,
        tagIds: const [],
      ),
    ],
  );
  AuthoringDocument title(skir.DataValue value) {
    final entry = base.entry(id)!;
    return base.copyWith(
      entries: {
        ...base.entries,
        id: skir.AuthoringResource(
          id: id,
          content: skir.AuthoringRecord(
            configuration: entry.content.configuration,
            fields: [
              for (final field in entry.content.fields)
                if (field.name == "title")
                  skir.FieldValue(name: field.name, value: value)
                else
                  field,
            ],
          ),
        ),
      },
    );
  }

  RealmPublicationView saved(
    AuthoringDocument document, {
    bool evidence = true,
  }) => RealmPublicationView.blocked(
    skir.PublicationStatus_Blocked(
      baseline: skir.PublicationBaseline.initial,
      blockers: skir.PublicationBlockers(
        first: skir.PublicationBlocker(
          details: skir.PublicationDiagnosticDetails(
            id: skir.DiagnosticId(value: "original"),
            origin: skir.RuleOrigin(
              owner: skir.TypeDefinitionId(
                typeId: skir.TypeId.createQualified(
                  namespace: "typewriter",
                  name: "publication",
                ),
                revision: 1,
              ),
              ordinal: 0,
            ),
            code: "unfinished_value",
            message: "A required value is unfinished.",
            primary: at,
            related: const [],
            evidence: evidence
                ? skir.DiagnosticEvidence(
                    catalog: document.generation,
                    expectations: [
                      skir.EditExpectation.createResource(
                        id: id,
                        expected: document.resource(id),
                      ),
                    ],
                  )
                : null,
          ),
        ),
        additional: const [],
      ),
      notices: const [],
      confirmedChanges: const [],
      pendingRoots: const [],
    ),
  );

  test(
    "local and witnessed saved causes share one issue and original identity",
    () {
      final document = title(skir.DataValue.unfilled);
      final issues = ResourceIssues.evaluate(
        document: document,
        publication: saved(document),
      );
      final unfinished = issues.findings
          .where((f) => f.diagnostic.code == "unfinished_value")
          .toList();
      expect(unfinished, hasLength(1));
      expect(unfinished.single.current, isTrue);
      expect(unfinished.single.saved, isTrue);
      expect(unfinished.single.diagnostic.id?.value, "original");
      expect(unfinished.single.primary, at);
    },
  );

  test("fixing an unsaved value clears current red state but preserves saved blocker", () {
    final previous = title(skir.DataValue.unfilled);
    final issues = ResourceIssues.evaluate(
      document: base,
      publication: saved(previous),
    );
    expect(
      issues
          .currentFor(id)
          .where((f) => f.diagnostic.code == "unfinished_value"),
      isEmpty,
    );
    expect(issues.savedFor(id).single.blocksPublication, isTrue);
    expect(issues.savedFor(id).single.current, isFalse);
  });

  test(
    "retained publication reviews cannot refresh external runtime evidence",
    () {
      final review = saved(base);
      expect(review.projectSavedIssues(base).single.current, isTrue);
      for (final retained in [
        RealmPublicationView.checking(display: review.review),
        RealmPublicationView.unavailable("Offline", display: review.review),
        RealmPublicationView.requestActive(display: review.review),
        RealmPublicationView.uncertain(
          "Unknown outcome",
          display: review.review,
        ),
      ]) {
        final issue = retained.projectSavedIssues(base).single;
        expect(issue.saved, isTrue);
        expect(issue.blocksPublication, isTrue);
        expect(issue.current, isFalse);
        expect(issue.outdated, isTrue);
      }
    },
  );

  test("missing witnesses never make saved findings current", () {
    final issues = ResourceIssues.evaluate(
      document: base,
      publication: saved(base, evidence: false),
    );
    expect(issues.savedFor(id).single.current, isFalse);
  });

  test("catalog replacement invalidates saved applicability", () {
    final snapshot = base.catalog.snapshot.toMutable()
      ..generation = skir.CatalogGeneration(value: "replacement").toMutable();
    final changed = base.copyWith(
      catalog: CheckedEditorCatalog(snapshot.toFrozen()),
    );
    final issues = ResourceIssues.evaluate(
      document: changed,
      publication: saved(base),
    );
    expect(issues.savedFor(id).single.current, isFalse);
  });
}
