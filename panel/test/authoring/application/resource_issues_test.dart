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
        publication: RealmPublicationView.blocked(
          blockedPublicationReview(
            problem: publicationProblem(
              id: "original",
              code: "unfinished_value",
              message: "A required value is unfinished.",
              primary: at,
              origin: origin,
              evidence: document.evidenceOf(id),
            ),
          ),
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
      publication: RealmPublicationView.blocked(
        blockedPublicationReview(
          problem: publicationProblem(
            id: "original",
            code: "unfinished_value",
            message: "A required value is unfinished.",
            primary: at,
            origin: origin,
            evidence: previous.evidenceOf(id),
          ),
        ),
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
      final review = RealmPublicationView.blocked(
        blockedPublicationReview(
          problem: publicationProblem(
            id: "original",
            code: "unfinished_value",
            message: "A required value is unfinished.",
            primary: at,
            origin: origin,
            evidence: base.evidenceOf(id),
          ),
        ),
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

  test("missing witnesses never make saved findings current", () {
    final issues = ResourceIssues.evaluate(
      document: base,
      publication: RealmPublicationView.blocked(
        blockedPublicationReview(
          problem: publicationProblem(
            id: "original",
            code: "unfinished_value",
            message: "A required value is unfinished.",
            primary: at,
            origin: origin,
          ),
        ),
      ),
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
      publication: RealmPublicationView.blocked(
        blockedPublicationReview(
          problem: publicationProblem(
            id: "original",
            code: "unfinished_value",
            message: "A required value is unfinished.",
            primary: at,
            origin: origin,
            evidence: base.evidenceOf(id),
          ),
        ),
      ),
    );
    expect(issues.savedFor(id).single.current, isFalse);
  });
}
