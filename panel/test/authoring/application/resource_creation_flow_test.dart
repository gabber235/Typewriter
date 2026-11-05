import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets(
    "a page with a new Book in the single Library is created in one edit",
    (tester) async {
      final fixture = ResourceCreationFixture.library();
      final page = fixture.request("Page");
      final panel = await tester.pumpPanel(
        adaServing(fixture.libraryDocument()),
      );

      final creation = await panel.create(page);
      await panel.search.result("Create Book").tap();

      expect(creation.error, isNull);
      expect(creation.created?.resourceId, page.id);
      // The Book joins the only Library without a question.
      expect(panel.search.result("Library").isShown, isFalse);
      final saved = await panel.savedAfter();
      final book = saved.linkTarget(page.id, "book")!;
      expect(saved.linkTarget(book, "library"), fixture.library);
      expect(saved.relations.children[fixture.library], [book]);
      expect(saved.relations.children[book], [page.id]);
    },
  );

  testWidgets(
    "an owner back reference the Realm leaves empty still joins the single "
    "owner",
    (tester) async {
      final fixture = ResourceCreationFixture.library();
      final book = fixture.request("Book");
      final panel = await tester.pumpPanel(
        adaServing(fixture.libraryDocument()),
      );
      final realm = panel.world.requireRealm;
      // A nullable back reference prepares as null instead of asking.
      realm.answerPrepareStep = (step) async => switch (realm.document
          .prepareStep(step)) {
        skir.PrepareValueResult_needsInputWrapper(:final value) =>
          skir.PrepareValueResult.wrapReady(
            skir.PreparedValue(
              content: skir.PreparedContent.wrapRecord(switch ((value.content
                      as skir.PreparedContent_recordWrapper)
                  .value
                  .replaceAt(
                    editorRootPath.field("library"),
                    skir.DataValue.null_,
                  )) {
                PortablePathValue(:final value) => value,
                PortablePathUnavailable(:final message) => throw StateError(
                  message,
                ),
              }),
              findings: const [],
            ),
          ),
        final answer => answer,
      };

      final creation = await panel.create(book);

      expect(creation.error, isNull);
      expect(creation.created?.resourceId, book.id);
      final saved = await panel.savedAfter();
      expect(saved.linkTarget(book.id, "library"), fixture.library);
      expect(saved.relations.parents[book.id], [fixture.library]);
    },
  );

  testWidgets(
    "a type owned only from the owner side asks for its owner and joins it",
    (tester) async {
      final fixture = ResourceCreationFixture();
      final other = skir.ResourceId(value: "store:other");
      final book = fixture.request("Book");
      final panel = await tester.pumpPanel(
        adaServing(fixture.withStores(fixture.document(), [other])),
      );

      final creation = await panel.create(book);
      expect(panel.search.result(other.value).isShown, isTrue);
      expect(panel.search.result(fixture.store.value).isShown, isTrue);
      await panel.search.result(other.value).tap();

      expect(creation.error, isNull);
      expect((await panel.savedAfter()).relations.parents[book.id], [other]);
    },
  );

  testWidgets(
    "a type owned only from the owner side joins the owner its creation names",
    (tester) async {
      final fixture = ResourceCreationFixture();
      final other = skir.ResourceId(value: "store:other");
      final book = fixture.request("Book");
      final document = fixture.withStores(fixture.document(), [other]);
      final panel = await tester.pumpPanel(adaServing(document));

      final creation = await panel.create(
        book,
        context: ownerCreationContext(
          document,
          skir.ValueLocation(
            resource: other,
            path: editorRootPath.field("ownedBook"),
          ),
        ),
      );

      expect(creation.error, isNull);
      expect(creation.created?.resourceId, book.id);
      expect((await panel.savedAfter()).relations.parents[book.id], [other]);
    },
  );

  testWidgets(
    "a compatible current page satisfies the required reference without a "
    "picker",
    (tester) async {
      final fixture = ResourceCreationFixture();
      final entry = fixture.request("Entry");
      final panel = await tester.pumpPanel(
        adaServing(fixture.document(existing: true)),
      );

      final creation = await panel.create(
        entry,
        context: CreationContext(preferredResources: [fixture.page]),
      );

      expect(creation.error, isNull);
      expect(creation.created?.resourceId, entry.id);
      final saved = await panel.savedAfter();
      expect(saved.linkTarget(entry.id, "page"), fixture.page);
      expect(
        saved.resource(fixture.page)!.authoredField("elements")!.authoredItems,
        hasLength(1),
      );
    },
  );

  testWidgets(
    "a scope naming two Books asks between exactly those, ignoring ambient "
    "preference",
    (tester) async {
      final fixture = ResourceCreationFixture.library();
      final first = skir.ResourceId(value: "book:first");
      final other = skir.ResourceId(value: "book:other");
      final document = fixture.withBooks(fixture.libraryDocument(), [
        first,
        other,
      ]);
      final page = fixture.request("Page");
      final pageBook = document.catalog.ownershipRelations
          .singleWhere(
            (ownership) => ownership.member.resource.definition == page.type,
          )
          .member
          .id;
      final panel = await tester.pumpPanel(adaServing(document));

      final creation = await panel.create(
        page,
        context: CreationContext(
          constraints: [
            CreationReferenceConstraint(
              route: [pageBook],
              targets: {first, other},
            ),
          ],
          preferredResources: [first],
        ),
      );

      expect(creation.error, isNull);
      expect(panel.search.result(first.value).isShown, isTrue);
      expect(panel.search.result(other.value).isShown, isTrue);
      expect(panel.search.result("Create Book").isShown, isFalse);
      // The first Escape leaves typing in the search field, the second closes
      // the choice.
      await panel.press(LogicalKeyboardKey.escape);
      await panel.press(LogicalKeyboardKey.escape);
      expect(creation.done, isTrue);
      expect(creation.created, isNull);
      expect(panel.world.requireRealm.saves, isEmpty);
    },
  );

  testWidgets("missing page and Book are created with the entry in one edit", (
    tester,
  ) async {
    final fixture = ResourceCreationFixture();
    final entry = fixture.request("Entry");
    final panel = await tester.pumpPanel(adaServing(fixture.document()));

    final creation = await panel.create(entry);
    await panel.search.result("Create Page").tap();
    // Nothing is staged while the creation still asks.
    expect(panel.workingDocument.entries.keys, [fixture.store]);
    await panel.search.result("Create Book").tap();

    expect(creation.error, isNull);
    expect(creation.created?.resourceId, entry.id);
    final saved = await panel.savedAfter();
    final page = saved.linkTarget(entry.id, "page")!;
    final book = saved.linkTarget(page, "book")!;
    expect(
      saved.resource(book)!.authoredField("pages")!.authoredItems,
      hasLength(1),
    );
    expect(
      saved.resource(page)!.authoredField("elements")!.authoredItems,
      hasLength(1),
    );
    // Every created resource also joins the single store.
    expect(
      saved.relations.children[fixture.store],
      unorderedEquals([entry.id, page, book]),
    );
  });

  testWidgets(
    "Escape during nested Book selection leaves no admitted resources",
    (tester) async {
      final fixture = ResourceCreationFixture();
      final panel = await tester.pumpPanel(adaServing(fixture.document()));

      final creation = await panel.create(fixture.request("Entry"));
      await panel.search.result("Create Page").tap();
      // The first Escape leaves typing in the search field, the second closes
      // the choice.
      await panel.press(LogicalKeyboardKey.escape);
      await panel.press(LogicalKeyboardKey.escape);

      expect(creation.error, isNull);
      expect(creation.done, isTrue);
      expect(creation.created, isNull);
      expect(panel.workingDocument.entries.keys, [fixture.store]);
      expect(panel.world.requireRealm.saves, isEmpty);
    },
  );

  testWidgets("the keyboard reaches Back from the query of a nested choice "
      "and returns to the parent choice with its query", (tester) async {
    final fixture = ResourceCreationFixture();
    final panel = await tester.pumpPanel(
      adaServing(fixture.document(existing: true)),
    );

    await panel.create(fixture.request("Entry"));
    await panel.queryBar.type("Page");
    await panel.search.result("Create Page").tap();
    expect(panel.queryBar.isFocused, isTrue);
    // Back sits before the query in focus order: the first Shift+Tab leaves
    // the text to the query bar, the second reaches Back.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await panel.press(LogicalKeyboardKey.tab);
    await panel.press(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(panel.hasFocusOn("Back"), isTrue);
    await panel.press(LogicalKeyboardKey.enter);

    expect(panel.search.result("Create Page").isShown, isTrue);
    expect(panel.queryBar.text, "Page");
  });

  testWidgets(
    "Back from a nested choice leaves nothing pending and another parent "
    "can be chosen",
    (tester) async {
      final fixture = ResourceCreationFixture();
      final entry = fixture.request("Entry");
      final panel = await tester.pumpPanel(
        adaServing(fixture.document(existing: true)),
      );

      final creation = await panel.create(entry);
      await panel.search.result("Create Page").tap();
      await panel.tapOn(find.bySemanticsLabel("Back"));
      await panel.search.result(fixture.page.value).tap();

      expect(creation.error, isNull);
      expect(creation.created?.resourceId, entry.id);
      final saved = await panel.savedAfter();
      expect(saved.linkTarget(entry.id, "page"), fixture.page);
      // The page the abandoned choice started is gone with it.
      expect(saved.entries, hasLength(4));
    },
  );

  testWidgets("an ordinary required reference can create its target", (
    tester,
  ) async {
    final fixture = ResourceCreationFixture();
    final report = fixture.request("Report");
    final panel = await tester.pumpPanel(adaServing(fixture.document()));

    final creation = await panel.create(report);
    await panel.search.result("Create Book").tap();

    expect(creation.error, isNull);
    final saved = await panel.savedAfter();
    final link = fixture.authoredLinks(saved).single;
    expect(link.contract.value, "review");
    expect(link.first, report.id);
    expect(saved.resource(link.second), isNotNull);
  });

  testWidgets("a pending ancestor closes an ordinary reference cycle", (
    tester,
  ) async {
    final fixture = ResourceCreationFixture();
    final a = fixture.request("A");
    final panel = await tester.pumpPanel(adaServing(fixture.document()));

    final creation = await panel.create(a);
    await panel.search.result("Create B").tap();
    await panel.search.result("A").tap();

    expect(creation.error, isNull);
    final saved = await panel.savedAfter();
    final b = saved.linkTarget(a.id, "b")!;
    expect(saved.linkTarget(b, "a"), a.id);
  });

  testWidgets(
    "a selected concrete form resolves its nested required reference",
    (tester) async {
      final fixture = ResourceCreationFixture(abstractReport: true);
      final report = fixture.request("Report");
      final panel = await tester.pumpPanel(adaServing(fixture.document()));

      final creation = await panel.create(report);
      await panel.search.result("EmailDelivery").tap();
      await panel.search.result("Create Book").tap();

      expect(creation.error, isNull);
      expect(creation.created?.resourceId, report.id);
      final saved = await panel.savedAfter();
      final recipient = saved
          .resource(report.id)!
          .authoredField("payload")!
          .authoredField("recipient")!
          .authoredLink!;
      expect(saved.resource(recipient.target.resource), isNotNull);
      expect(fixture.authoredLinks(saved), hasLength(1));
    },
  );
}
