import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final id = skir.ResourceId(value: "book:issues");
  final at = skir.ValueLocation(
    resource: id,
    path: skir.ValuePath(
      segments: [skir.PathSegment.createField(name: "title")],
    ),
  );
  final base = realmDocument(
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
  final unfilled = base.changedRemotely(
    (edit) => edit.set(at, skir.DataValue.unfilled),
  );
  final origin = skir.RuleOrigin(
    owner: skir.TypeDefinitionId(
      typeId: skir.TypeId.createQualified(
        namespace: "typewriter",
        name: "publication",
      ),
      revision: 1,
    ),
    ordinal: 0,
  );

  test(
    "local and witnessed saved causes share one issue and original identity",
    () {
      final document = unfilled;
      final issues = ResourceIssues.evaluate(
        document: document,
        publication: unfinishedValueBlocking(
          at,
          origin: origin,
          evidence: document.evidenceOf(id),
        ),
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
    final previous = unfilled;
    final issues = ResourceIssues.evaluate(
      document: base,
      publication: unfinishedValueBlocking(
        at,
        origin: origin,
        evidence: previous.evidenceOf(id),
      ),
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
      final review = unfinishedValueBlocking(
        at,
        origin: origin,
        evidence: base.evidenceOf(id),
      );
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

  test("a document with an unsaved create keeps a saved finding current", () {
    // The Realm's evidence is exactly what the check read: the saved title,
    // not which resources exist.
    final set = findingSet(
      realmDiagnostic("title", at),
      facts: [textExpectation(at, "Harbor")],
    );
    final other = skir.ResourceId(value: "book:other");
    final working = base.changedRemotely(
      (edit) => edit.create(other, base.resource(id)!),
    );

    final issues = ResourceIssues.evaluate(
      document: working,
      publication: RealmPublicationView.checking(
        display: skir.PublicationStatus.createChecking(
          baseline: skir.PublicationBaseline.initial,
          findings: [set],
        ),
      ),
    );

    expect(issues.savedFor(id).single.current, isTrue);
  });

  test("a saved finding keeps the realm's answer for a scope and is judged by its facts", () {
    // The scope names a resource this document does not hold: only the
    // Realm knows what the name means, so the panel keeps its answer.
    final set = findingSet(
      realmDiagnostic("title", at),
      facts: [textExpectation(at, "Harbor")],
      scopes: [
        skir.CheckEvidence_Scope(
          at: at,
          name: "reward",
          expected: [skir.ResourceId(value: "item:unseen")],
        ),
      ],
    );
    final reported = RealmPublicationView.checking(
      display: skir.PublicationStatus.createChecking(
        baseline: skir.PublicationBaseline.initial,
        findings: [set],
      ),
    );
    final retitled = base.changedRemotely(
      (edit) => edit.set(at, skir.DataValue.wrapStringValue("Lighthouse")),
    );

    final kept = ResourceIssues.evaluate(document: base, publication: reported);
    final judged = ResourceIssues.evaluate(
      document: retitled,
      publication: reported,
    );

    expect(kept.savedFor(id).single.current, isTrue);
    expect(judged.savedFor(id).single.current, isFalse);
  });

  test("missing witnesses never make saved findings current", () {
    final issues = ResourceIssues.evaluate(
      document: base,
      publication: unfinishedValueBlocking(at, origin: origin),
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
      publication: unfinishedValueBlocking(
        at,
        origin: origin,
        evidence: base.evidenceOf(id),
      ),
    );
    expect(issues.savedFor(id).single.current, isFalse);
  });

  test(
    "a finding whose evidence holds a types fact stays current and shows",
    () {
      final issues = ResourceIssues.evaluate(
        document: base,
        publication: unfinishedValueBlocking(
          at,
          origin: origin,
          evidence: skir.DiagnosticEvidence(
            catalog: base.generation,
            evidence: [
              skir.CheckEvidence.wrapFact(
                skir.EditExpectation.createTypes(
                  resource: id,
                  expected: const [],
                ),
              ),
            ],
          ),
        ),
      );
      final saved = issues.savedFor(id).single;
      expect(saved.current, isTrue);
      expect(saved.blocksPublication, isTrue);
    },
  );

  test("a resource with a content type argument shows no unavailable type", () {
    final box = skir.ResourceId(value: "box");
    final reward = contentTypeDefinition("box", "k1");
    final document = base
        .withCatalogEntries(
          types: [
            declaredRecord("Box", parameters: {"T": []}),
          ],
        )
        .changedRemotely(
          (edit) => edit.create(
            box,
            skir.AuthoringRecord(
              types: [contentRecordDeclaration(reward)],
              configuration: selectionOfUse(
                skir.NamedTypeUse(
                  definition: typeDefinition("Box"),
                  arguments: [
                    skir.TypeUse.createNamed(
                      definition: reward,
                      arguments: const [],
                    ),
                  ],
                ),
              ),
              fields: const [],
            ),
          ),
        );

    final issues = ResourceIssues.evaluate(document: document);

    expect(
      issues.currentFor(box).map((issue) => issue.diagnostic.code),
      isNot(contains("unresolved_type")),
    );
  });
}
