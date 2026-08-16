import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart" hide Tags;
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../../../support/test_utils.dart";

class _Books extends Books {
  _Books(this.books);

  final List<Book> books;

  @override
  Stream<List<Book>> build() => Stream.value(books);
}

class _Tags extends Tags {
  _Tags(this.tags);

  final List<Tag> tags;

  @override
  Stream<List<Tag>> build() => Stream.value(tags);
}

final _refProvider = Provider<Ref>((ref) => ref);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("Book inspector exposes direct and effective Tags", () async {
    final directTag = Tag(
      tagId: recordId("tag:direct"),
      revision: 1,
      name: "Direct",
      color: Colors.blue,
      parentIds: [recordId("tag:parent")],
      placement: const Placement(x: 0, y: 0, width: 4, height: 1),
    );
    final parentTag = Tag(
      tagId: recordId("tag:parent"),
      revision: 1,
      name: "Parent",
      color: Colors.green,
      parentIds: const [],
      placement: const Placement(x: 0, y: 0, width: 4, height: 1),
    );
    final book = Book(
      bookId: recordId("book:test"),
      revision: 4,
      title: "Test Book",
      icon: "mdi:book",
      color: Colors.deepPurple,
      tagIds: [directTag.tagId],
    );
    final container = ProviderContainer.test(
      overrides: [
        booksProvider.overrideWith(() => _Books([book])),
        tagsProvider.overrideWith(() => _Tags([directTag, parentTag])),
      ],
    );
    final bookSubscription = container.listen(
      booksProvider,
      (_, _) {},
      fireImmediately: true,
    );
    final tagSubscription = container.listen(
      tagsProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(bookSubscription.close);
    addTearDown(tagSubscription.close);
    await Future.wait([
      container.read(booksProvider.future),
      container.read(tagsProvider.future),
    ]);
    container
        .read(selectionProvider.notifier)
        .select(BookIdentifier(book.bookId));

    final selected = await _selected(container);
    final document = (selected as BookSelection).document;
    final resolved = TypeRegistry(
      document.typeCatalog,
    ).resolve(document.rootType as NamedType);
    final root = document.presentations.single.root.element as ColumnElement;
    final direct =
        root.children
                .singleWhere((node) => node.id == "book.tags.search")
                .element
            as SearchInputElement;
    final effectiveVisibility =
        root.children
                .singleWhere(
                  (node) => node.id == "book.effectiveTags.visibility",
                )
                .element
            as ConditionalElement;
    final effectiveSection =
        effectiveVisibility.whenTrue.element as SectionElement;
    final effective = effectiveSection.child.element as CollectionGraphElement;
    final directSummary = direct.summary!.element as RepeatedElement;
    final summaryLookup =
        directSummary.presentation.item.element as CollectionLookupElement;
    final summaryChip = summaryLookup.found.element as ChipElement;

    expect(document.revision, 4);
    expect(resolved.diagnostics, isEmpty);
    expect(resolved.valueOrNull, isNotNull);
    expect(document.collections.single.id, tagCollectionSourceId);
    expect(document.mergePolicies, {
      DataPath.root.field("tags"): EditorMergePolicy.set,
    });
    expect(direct.selectionMode, SearchSelectionMode.multiple);
    expect(direct.provider, isA<CollectionSearchProvider>());
    expect(directSummary.presentation.layout, isA<PresentationWrapLayout>());
    expect(directSummary.presentation.empty, isNotNull);
    _expectTagChip(summaryChip);
    expect(effective.sourceId, tagCollectionSourceId);
    expect(effective.relation, tagInheritsRelationId);
    expect(effective.direction, CollectionGraphDirection.forward);
    expect(effective.rootRows!.layout, isA<PresentationWrapLayout>());
    expect(effective.reachedRows!.layout, isA<PresentationWrapLayout>());
    _expectTagChip(effective.rootRows!.item.element as ChipElement);
    _expectTagChip(effective.reachedRows!.item.element as ChipElement);

    final path = effective.paths!.item.element as CollapsibleElement;
    final pathItems = path.child.element as RepeatedElement;
    expect(pathItems.presentation.layout, isA<PresentationWrapLayout>());
    expect(
      (pathItems.presentation.separator!.element as TextElement).value,
      "›".asStringLiteral,
    );
    final pathLookup =
        pathItems.presentation.item.element as CollectionLookupElement;
    _expectTagChip(pathLookup.found.element as ChipElement);
  });

  testWidgets(
    "empty direct Tags remain editable while Effective Tags stay hidden",
    (tester) async {
      final book = Book(
        bookId: recordId("book:empty"),
        revision: 1,
        title: "Empty Book",
        icon: "mdi:book",
        color: Colors.deepPurple,
        tagIds: const [],
      );
      final container = ProviderContainer.test();
      final selected = BookSelection(
        ref: container.read(_refProvider),
        id: BookIdentifier(book.bookId),
        book: book,
        tagCollection: tagPresentationCollection(const []),
      );

      await tester.pumpTestApp(
        child: SizedBox(width: 400, child: _render(selected.document)),
        settle: false,
      );
      await tester.pumpAndSettle();

      expect(find.text("Direct Tags"), findsOneWidget);
      expect(find.text("None selected"), findsOneWidget);
      expect(find.text("Effective Tags"), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

void _expectTagChip(ChipElement chip) {
  expect(chip.color, isNotNull);
  final color = chip.color!.expression as BindingExpression;
  expect(color.binding.bindingId, tagCollectionRowBindingId);
  expect(color.binding.path, DataPath.root.field("color"));
}

EditorProtocolRenderer _render(EditorDocument document) =>
    EditorProtocolRenderer(
      envelope: TypedValueEnvelope(
        rootType: (document.rootType as NamedType).reference,
        rootValue: document.confirmedValue,
      ),
      typeCatalog: document.typeCatalog,
      collections: document.collections,
      presentations: document.presentations,
      presentation: document.presentations.single.root,
    );

Future<Selectable> _selected(ProviderContainer container) async {
  final completer = Completer<Selectable>();
  final subscription = container.listen(selectedProvider, (_, next) {
    if (!completer.isCompleted &&
        next.hasValue &&
        next.requireValue.isNotEmpty) {
      completer.complete(next.requireValue.single);
    } else if (!completer.isCompleted && next.hasError) {
      completer.completeError(next.error!, next.stackTrace);
    }
  }, fireImmediately: true);
  try {
    return await completer.future;
  } finally {
    subscription.close();
  }
}
