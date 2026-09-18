import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart" hide Tags;
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../../../support/test_utils.dart";

class _Books extends CanonicalBooks {
  _Books(this.books);

  final List<Book> books;

  @override
  Future<List<Book>> build() async => books;
}

class _Tags extends CanonicalTags {
  _Tags(this.tags);

  final List<Tag> tags;

  @override
  Future<List<Tag>> build() async => tags;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("Book inspector exposes direct and effective Tags", () async {
    final directTag = Tag(
      tagId: recordId("tag:direct"),
      name: "Direct",
      color: Colors.blue,
      parentIds: [recordId("tag:parent")],
      placement: const Placement(x: 0, y: 0, width: 4, height: 1),
    );
    final parentTag = Tag(
      tagId: recordId("tag:parent"),
      name: "Parent",
      color: Colors.green,
      parentIds: const [],
      placement: const Placement(x: 0, y: 0, width: 4, height: 1),
    );
    final book = Book(
      bookId: recordId("book:test"),
      title: "Test Book",
      icon: "mdi:book",
      color: Colors.deepPurple,
      tagIds: [directTag.tagId],
    );

    final container = ProviderContainer.test(
      overrides: [
        organizationIdProvider.overrideWithValue(recordId("organization:test")),
        realmIdProvider.overrideWithValue(recordId("realm:test")),
        authoringSessionProvider(
          recordId("organization:test"),
          recordId("realm:test"),
        ).overrideWithValue(
          AuthoringSessionState(
            sequence: 1,
            books: {book.bookId: book.toWire()},
            tags: {
              directTag.tagId: directTag.toWire(),
              parentTag.tagId: parentTag.toWire(),
            },
          ),
        ),
        natsProvider.overrideWithValue(FakeNatsClient()),
        panelTelemetryProvider.overrideWithValue(
          const AsyncData(NoopPanelTelemetry()),
        ),
        canonicalBooksProvider.overrideWith(() => _Books([book])),
        canonicalTagsProvider.overrideWith(() => _Tags([directTag, parentTag])),
      ],
    );
    final bookSubscription = container.listen(
      canonicalBooksProvider,
      (_, _) {},
      fireImmediately: true,
    );
    final tagSubscription = container.listen(
      canonicalTagsProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(bookSubscription.close);
    addTearDown(tagSubscription.close);
    await Future.wait([
      container.read(canonicalBooksProvider.future),
      container.read(canonicalTagsProvider.future),
    ]);

    container
        .read(selectionProvider.notifier)
        .select(BookIdentifier(book.bookId));

    final selected = await _selected(container);
    final open = selected.capabilities
        .whereType<OpenSelectionCapability>()
        .single;

    expect(open.allowMultiSelect, isFalse);
    final inspector = selected as BookSelection;
    final document = inspector.document;
    final resolved = TypeRegistry(document.typeCatalog)
        .resolve(document.rootType as NamedType);
    final root = inspector.presentations.single.root.element as ColumnElement;
    final direct =
        root.children.singleWhere((node) => node.id == "book.tags").element
            as ReferenceInputElement;

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
    expect(document.revision, 1);
    expect(resolved.diagnostics, isEmpty);
    expect(resolved.valueOrNull, isNotNull);
    expect(inspector.collections.single.id, tagCollectionSourceId);
    expect(document.mergePolicies, {
      DataPath.root.field("tags"): EditorMergePolicy.set,
    });
    expect(direct.allowReorder, isFalse);
    expect(direct.candidatePolicy, isNull);
    expect(effective.sourceId, tagCollectionSourceId);

    expect(effective.relation, tagInheritsRelationId);
    expect(effective.direction, CollectionGraphDirection.forward);
    expect(effective.childrenBindingId, const BindingId(45));
    expect(effective.childBindingId, const BindingId(46));

    expect(effective.node.presentationSlotIds, {"book.effectiveTags.children"});
    final hierarchy =
        effective.children.layout as PresentationHierarchySequenceLayout;
    expect(hierarchy.layout.itemAnchor, isA<CenterConnectorAnchor>());
    expect(
      hierarchy.layout.crossAxisAlignment,
      PresentationCrossAxisAlignment.stretch,
    );
    final branching = effective.node.element as ConditionalElement;
    final branchNode = branching.whenTrue;

    final branch = branchNode.element as SectionElement;
    expect(branch.border, isA<PresentationBorderSides>());
    final branchBorder = branch.border! as PresentationBorderSides;
    expect(branchBorder.top, isNull);
    expect(branchBorder.start?.width, 4);
    expect(branchBorder.end, isNull);

    expect(branchBorder.bottom, isNull);
    expect(branch.child.element, isA<PresentationSlotElement>());
    final branchTitle = branchNode.header!.title;
    expect(branchTitle, isA<PresentationHeaderNodeTitle>());
    final containerNode = (branchTitle! as PresentationHeaderNodeTitle).node;
    expect(containerNode.element, isA<ContainerElement>());
  });

  testWidgets(
    "empty direct Tags remain editable while Effective Tags stay hidden",
    (tester) async {
      final book = Book(
        bookId: recordId("book:empty"),
        title: "Empty Book",
        icon: "mdi:book",
        color: Colors.deepPurple,
        tagIds: const [],
      );
      final selected = BookSelection(
        resource: FakeEditableResource(
          key: EditorResourceKey(scope: null, identity: book.bookId),
          current: BookEditorSnapshot(book, 1),
          commit: (_) async =>
              throw StateError("No save in this rendering test"),
        ),
        onOpen: null,
        id: BookIdentifier(book.bookId),
        book: book,
        revision: 1,
        tagCollection: const <Tag>[].presentationCollection(),
      );

      await tester.pumpTestApp(
        child: SizedBox(width: 400, child: _render(selected)),
        settle: false,
      );
      await tester.pumpAndSettle();

      expect(find.text("Direct Tags"), findsOneWidget);
      expect(find.text("Reference search is unavailable"), findsOneWidget);
      expect(find.text("Effective Tags"), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  test("Book multi inspection rejects inconsistent Tag collections", () {
    final first = _bookSelection(
      "first",
      [_tag("shared", Colors.blue)].presentationCollection(),
    );
    final second = _bookSelection(
      "second",
      [_tag("shared", Colors.red)].presentationCollection(),
    );

    final result = [first, second].sharedBookTagCollection;

    expect(result.valueOrNull, isNull);
    expect(
      result.diagnostics.single.message,
      "Selected Books have inconsistent Tag collections",
    );
  });
}

BookSelection _bookSelection(
  String id,
  PresentationCollectionSource tagCollection,
) {
  final book = Book(
    bookId: recordId("book:$id"),
    title: id,
    icon: "mdi:book",
    color: Colors.blue,
    tagIds: const [],
  );
  return BookSelection(
    resource: FakeEditableResource(
      key: EditorResourceKey(scope: null, identity: book.bookId),
      current: BookEditorSnapshot(book, 1),
      commit: (_) async => throw StateError("No save in this domain test"),
    ),
    onOpen: null,
    id: BookIdentifier(book.bookId),
    book: book,
    revision: 1,
    tagCollection: tagCollection,
  );
}

Tag _tag(String id, Color color) => Tag(
  tagId: recordId("tag:$id"),
  name: id,
  color: color,
  parentIds: const [],
  placement: const Placement(x: 0, y: 0, width: 4, height: 1),
);

EditorProtocolRenderer _render(EditableSelectable inspector) =>
    EditorProtocolRenderer(
      envelope: TypedValueEnvelope(
        rootType: (inspector.document.rootType as NamedType).reference,
        rootValue: inspector.document.confirmedValue,
      ),
      typeCatalog: inspector.document.typeCatalog,
      collections: inspector.collections,
      presentations: inspector.presentations,
      presentation: inspector.presentations.single.root,
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
