import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  test("creation option identity includes unfinished type arguments", () {
    final type = testTypeId("Book");
    final first = AuthoringCreationOption(
      type: type,
      configuration: skir.TypeSelection.createPending(
        definition: type,
        arguments: [
          skir.ArgumentSelection.wrapChosen(
            skir.TypeUse.wrapScalar(skir.ScalarKind.text),
          ),
        ],
      ),
      label: "Book",
    );
    final second = AuthoringCreationOption(
      type: type,
      configuration: skir.TypeSelection.createPending(
        definition: type,
        arguments: [
          skir.ArgumentSelection.wrapChosen(
            skir.TypeUse.wrapScalar(skir.ScalarKind.boolean),
          ),
        ],
      ),
      label: "Book",
    );

    expect(first.id, isNot(second.id));
  });

  testWidgets(
    "creation search offers the concrete resources an owner can hold",
    (tester) async {
      final panel = await tester.pumpPanel(adaServing(emptyShelfDocument()));
      final controller = await panel.creationSearch();

      expect(controller.snapshot.status, SearchSourceStatus.ready);
      final section = controller.snapshot.nodes.single as SearchSectionNode;
      expect(
        section.children.whereType<SearchResultNode>().map(
          (node) => (node.result.payload as AuthoringCreationOption).type,
        ),
        unorderedEquals([testTypeId("Book"), testTypeId("SimpleMessage")]),
      );
      for (final type in ["Book", "SimpleMessage"]) {
        expect(
          controller.creationOption(testTypeId(type)).configuration,
          skir.TypeSelection.createComplete(
            definition: testTypeId(type),
            arguments: const [],
          ),
        );
      }
    },
  );

  testWidgets("a creation option reads the label, description, icon and "
      "color its type declares", (tester) async {
    final panel = await tester.pumpPanel(adaServing(emptyShelfDocument()));
    final controller = await panel.creationSearch();

    final book = controller.creationOption(testTypeId("Book"));

    expect(book.label, "Quest Book");
    expect(book.display?.description, "A reusable quest collection");
    expect(book.display?.icon, skir.Icon.wrapIconify("material-symbols:book"));
    expect(book.display?.color, skir.Color(argb: 0xff3f51b5.toSigned(32)));
  });

  testWidgets("creation search does not depend on ownership endpoint order", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(
      adaServing(
        AuthoringDocument(
          catalog: shelfCatalog(reversedOwnership: true),
          entries: const {},
          links: const [],
        ),
      ),
    );
    final controller = await panel.creationSearch();

    final section = controller.snapshot.nodes.single as SearchSectionNode;
    expect(
      section.children.whereType<SearchResultNode>().map(
        (node) => (node.result.payload as AuthoringCreationOption).type,
      ),
      containsAll([testTypeId("Book"), testTypeId("SimpleMessage")]),
    );
  });

  testWidgets("creation search filters by the resource label", (tester) async {
    final panel = await tester.pumpPanel(adaServing(emptyShelfDocument()));
    final controller = await panel.creationSearch();

    controller.updateQuery("Quest");
    await panel.settle();
    expect(
      (controller.snapshot.nodes.single as SearchSectionNode).children
          .whereType<SearchResultNode>()
          .map((node) => (node.result.payload as AuthoringCreationOption).type),
      [testTypeId("Book")],
    );

    controller.updateQuery("missing");
    await panel.settle();
    expect(controller.snapshot.nodes, isEmpty);
  });

  testWidgets(
    "scope keywords come from owner search keys and keep only types inside that scope",
    (tester) async {
      final panel = await tester.pumpPanel(adaServing(emptyShelfDocument()));
      final controller = await panel.creationSearch();
      final source = controller.source;

      expect(
        source.selectors.whereType<KeyValueSelectorDefinition>().map(
          (selector) => selector.key,
        ),
        unorderedEquals(["book:", "shelf:", "type:"]),
      );
      controller.updateQuery('book:"Lost tales"');
      await panel.settle();

      final option =
          ((controller.snapshot.nodes.single as SearchSectionNode)
                          .children
                          .single
                      as SearchResultNode)
                  .result
                  .payload
              as AuthoringCreationOption;
      expect(option.type, testTypeId("SimpleMessage"));
      expect(option.disabledReason, 'No Quest Book named "Lost tales"');
    },
  );

  testWidgets("type and text filters apply before the creation result limit", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(
      adaServing(
        AuthoringDocument(
          catalog: shelfCatalog(manyEntries: true),
          entries: const {},
          links: const [],
        ),
      ),
    );
    final controller = await panel.creationSearch();
    expect(
      (controller.snapshot.nodes.single as SearchSectionNode).children,
      hasLength(20),
    );
    controller.updateQuery("type:Entry ZMessage");
    await panel.settle();
    final section = controller.snapshot.nodes.single as SearchSectionNode;
    final option =
        (section.children.single as SearchResultNode).result.payload
            as AuthoringCreationOption;
    expect(option.label, "ZMessage");
    expect(option.type, testTypeId("ZMessage"));
    expect(
      option.configuration,
      skir.TypeSelection.createComplete(
        definition: testTypeId("ZMessage"),
        arguments: const [],
      ),
    );
  });
}
