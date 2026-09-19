import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/realm_runtime.dart";
import "package:widgetbook_workspace/support/selected_inspector_story.dart";

@widgetbook.UseCase(name: "Default", type: BookWidget)
Widget bookUseCase(BuildContext context) {
  final inheritedTag = Tag(
    tagId: recordId("tag:inherited_lore"),
    name: "inherited_lore",
    color: Colors.purple,
    parentIds: const [],
    placement: const Placement(x: 0, y: 0, width: 4, height: 1),
  );
  final directTag = Tag(
    tagId: recordId("tag:direct_story"),
    name: "direct_story",
    color: Colors.blue,
    parentIds: [inheritedTag.tagId],
    placement: const Placement(x: 0, y: 0, width: 4, height: 1),
  );
  final book = Book(
    bookId: recordId("book:widgetbook"),
    title: "widgetbook",
    icon: "mdi:book",
    color: Colors.teal,
    tagIds: [directTag.tagId],
  );

  return FakeApp(
    overrides: [
      ...authoringSessionMockOverrides(
        books: [book],
        tags: [directTag, inheritedTag],
      ),
      organizationIdProvider.overrideWithValue(
        recordId("organization:widgetbook"),
      ),
      realmIdProvider.overrideWithValue(recordId("service:widgetbook")),
      ...tagsProviderOverrides(tags: [directTag, inheritedTag]),
      canonicalBooksProvider.overrideWith(() => _BookStoryBooks([book])),
    ],
    child: InspectorScaffold(
      realmRuntime: storyRealmRuntime([directTag, inheritedTag]),
      child: const Center(child: _BookWidgetStory()),
    ),
  );
}

@widgetbook.UseCase(name: "Mixed selection", type: BookWidget)
Widget mixedBookSelectionUseCase(BuildContext context) =>
    mixedBookSelectionStory();

Widget mixedBookSelectionStory({bool initiallySelected = true}) {
  final lore = Tag(
    tagId: recordId("tag:lore"),
    name: "lore",
    color: Colors.purple,
    parentIds: const [],
    placement: const Placement(x: 0, y: 0, width: 4, height: 1),
  );
  final quest = Tag(
    tagId: recordId("tag:quest"),
    name: "quest",
    color: Colors.blue,
    parentIds: const [],
    placement: const Placement(x: 5, y: 0, width: 4, height: 1),
  );
  final books = [
    Book(
      bookId: recordId("book:earth"),
      title: "earth",
      icon: "mdi:earth",
      color: Colors.teal,
      tagIds: [lore.tagId],
    ),
    Book(
      bookId: recordId("book:mars"),
      title: "mars",
      icon: "mdi:rocket",
      color: Colors.teal,
      tagIds: [quest.tagId],
    ),
  ];

  return FakeApp(
    overrides: [
      ...authoringSessionMockOverrides(books: books, tags: [lore, quest]),
      organizationIdProvider.overrideWithValue(
        recordId("organization:widgetbook"),
      ),
      realmIdProvider.overrideWithValue(recordId("service:widgetbook")),
      ...tagsProviderOverrides(tags: [lore, quest]),
      canonicalBooksProvider.overrideWith(() => _BookStoryBooks(books)),
    ],
    child: InspectorScaffold(
      realmRuntime: storyRealmRuntime([lore, quest]),
      child: SelectedInspectorStory(
        selection: initiallySelected
            ? [for (final book in books) BookIdentifier(book.bookId)]
            : const [],
        child: const Center(child: _BookWidgetStory()),
      ),
    ),
  );
}

class _BookStoryBooks extends CanonicalBooks {
  _BookStoryBooks(List<Book> books) : _initialBooks = List.unmodifiable(books);

  final List<Book> _initialBooks;

  @override
  Future<List<Book>> build() async => _initialBooks;

  @override
  Future<TypedMutationResult> updateBook(Book book, {Book? expected}) async {
    state = AsyncData([
      for (final current in state.requireValue)
        if (current.bookId == book.bookId) book else current,
    ]);
    return TypedMutationResult.success(revision: 1, value: book.inspectorValue);
  }
}

class _BookWidgetStory extends ConsumerWidget {
  const _BookWidgetStory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(projectedBooksProvider);
    final tags = ref.watch(projectedTagsProvider).value ?? const <Tag>[];
    return books(
      name: "books",
      shrink: true,
      builder: (books) {
        final tagsById = {for (final tag in tags) tag.tagId: tag};
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final book in books)
              BookWidget(
                id: book.bookId,
                title: book.title,
                icon: Icones(book.icon),
                color: book.color,
                tags: book.tagIds
                    .map((tagId) => tagsById[tagId])
                    .nonNulls
                    .toList(),
              ),
          ],
        );
      },
    );
  }
}
