import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Default", type: BookWidget)
Widget bookUseCase(BuildContext context) {
  final inheritedTag = Tag(
    tagId: recordId("tag:inherited_lore"),
    revision: 1,
    name: "inherited_lore",
    color: Colors.purple,
    parentIds: const [],
    placement: const Placement(x: 0, y: 0, width: 4, height: 1),
  );
  final directTag = Tag(
    tagId: recordId("tag:direct_story"),
    revision: 1,
    name: "direct_story",
    color: Colors.blue,
    parentIds: [inheritedTag.tagId],
    placement: const Placement(x: 0, y: 0, width: 4, height: 1),
  );
  final book = Book(
    bookId: recordId("book:widgetbook"),
    revision: 1,
    title: "widgetbook",
    icon: "mdi:book",
    color: Colors.teal,
    tagIds: [directTag.tagId],
  );

  return FakeApp(
    overrides: [
      ...tagsProviderOverrides(tags: [directTag, inheritedTag]),
      booksProvider.overrideWith(() => _BookStoryBooks(book)),
    ],
    child: InspectorScaffold(child: const Center(child: _BookWidgetStory())),
  );
}

class _BookStoryBooks extends Books {
  _BookStoryBooks(this.book);

  final Book book;

  @override
  Stream<List<Book>> build() => Stream.value([book]);

  @override
  Future<TypedMutationResult> updateBook(Book book) async {
    final canonical = book.copyWith(revision: book.revision + 1);
    state = AsyncData([canonical]);
    return TypedMutationResult.success(
      revision: canonical.revision,
      value: bookMockInspectorValue(canonical),
    );
  }
}

class _BookWidgetStory extends ConsumerWidget {
  const _BookWidgetStory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(booksProvider);
    final tags = ref.watch(tagsProvider).value ?? const <Tag>[];
    return books(
      name: "books",
      shrink: true,
      builder: (books) {
        final book = books.first;
        final tagsById = {for (final tag in tags) tag.tagId: tag};
        return BookWidget(
          id: book.bookId,
          title: book.title,
          icon: Icones(book.icon),
          color: book.color,
          tags: book.tagIds.map((tagId) => tagsById[tagId]).nonNulls.toList(),
        );
      },
    );
  }
}
