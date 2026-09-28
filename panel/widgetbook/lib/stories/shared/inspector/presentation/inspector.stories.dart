import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/selected_inspector_story.dart";

@widgetbook.UseCase(name: "Default", type: InspectorScaffold)
Widget inspectorUseCase(BuildContext context) => const FakeApp(
  child: InspectorScaffold(
    child: Center(child: Text("Select an item to inspect")),
  ),
);

@widgetbook.UseCase(name: "Book plus Tag mixed color", type: InspectorScaffold)
Widget mixedBookAndTagColorUseCase(BuildContext context) =>
    bookAndTagSelectionStory(sharedColor: false);

@widgetbook.UseCase(name: "Book plus Tag shared color", type: InspectorScaffold)
Widget sharedBookAndTagColorUseCase(BuildContext context) =>
    bookAndTagSelectionStory(sharedColor: true);

Widget bookAndTagSelectionStory({required bool sharedColor}) {
  final book = Book(
    bookId: skir.ResourceId(value: "book:earth"),
    title: "earth",
    icon: "mdi:earth",
    color: Colors.teal,
    tagIds: const [],
  );
  final tag = Tag(
    tagId: skir.ResourceId(value: "tag:earth"),
    name: "earth",
    color: sharedColor ? Colors.teal : Colors.orange,
    parentIds: const [],
    placement: const GraphPlacement(x: 0, y: 0, width: 4, height: 1),
  );

  return FakeApp(
    overrides: [
      ...authoringSessionMockOverrides(books: [book], tags: [tag]),
      organizationIdProvider.overrideWithValue(
        recordId("organization:widgetbook"),
      ),
      realmIdProvider.overrideWithValue(recordId("service:widgetbook")),
      ...tagsProviderOverrides(tags: [tag]),
      canonicalBooksProvider.overrideWith(() => _HeterogeneousBooks(book)),
    ],
    child: InspectorScaffold(
      child: SelectedInspectorStory(
        selection: [BookIdentifier(book.bookId), TagIdentifier(tag.tagId)],
        child: Center(
          child: Wrap(
            spacing: 16,
            children: [
              BookWidget(
                id: book.bookId,
                title: book.title,
                icon: Icones(book.icon),
                color: book.color,
                tags: const [],
              ),
              SizedBox(
                width: 150,
                height: 50,
                child: TagNode(tagId: tag.tagId),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _HeterogeneousBooks extends CanonicalBooks {
  _HeterogeneousBooks(this.book);

  final Book book;

  @override
  Future<List<Book>> build() async => [book];

  @override
  Future<TypedMutationResult> updateBook(Book book, {Book? expected}) async {
    state = AsyncData([book]);
    return TypedMutationResult.success(revision: 1, value: book.inspectorValue);
  }
}
