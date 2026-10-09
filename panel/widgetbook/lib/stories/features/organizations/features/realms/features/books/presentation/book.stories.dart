import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/selected_inspector_story.dart";

@widgetbook.UseCase(name: "Default", type: BookWidget)
Widget bookUseCase(BuildContext context) {
  final inheritedTag = Tag(
    tagId: skir.ResourceId(value: "tag:inherited_lore"),
    name: "inherited_lore",
    color: Colors.purple,
    parentIds: const [],
    placement: const GraphPlacement(x: 0, y: 0, width: 4, height: 1),
  );
  final directTag = Tag(
    tagId: skir.ResourceId(value: "tag:direct_story"),
    name: "direct_story",
    color: Colors.blue,
    parentIds: [inheritedTag.tagId],
    placement: const GraphPlacement(x: 0, y: 0, width: 4, height: 1),
  );
  final book = Book(
    bookId: skir.ResourceId(value: "book:widgetbook"),
    title: "widgetbook",
    icon: "mdi:book",
    color: Colors.teal,
    tagIds: [directTag.tagId],
  );

  return AuthoringFixtureApp(
    createDocument: () => fixtureAuthoringDocument(
      books: [book],
      tags: [directTag, inheritedTag],
    ),
    overrides: [
      organizationIdProvider.overrideWithValue(
        skir.recordId("organization:widgetbook"),
      ),
      realmIdProvider.overrideWithValue(skir.recordId("service:widgetbook")),
    ],
    child: const InspectorScaffold(child: Center(child: _BookWidgetStory())),
  );
}

@widgetbook.UseCase(name: "Mixed selection", type: BookWidget)
Widget mixedBookSelectionUseCase(BuildContext context) =>
    mixedBookSelectionStory();

Widget mixedBookSelectionStory({bool initiallySelected = true}) {
  final lore = Tag(
    tagId: skir.ResourceId(value: "tag:lore"),
    name: "lore",
    color: Colors.purple,
    parentIds: const [],
    placement: const GraphPlacement(x: 0, y: 0, width: 4, height: 1),
  );
  final quest = Tag(
    tagId: skir.ResourceId(value: "tag:quest"),
    name: "quest",
    color: Colors.blue,
    parentIds: const [],
    placement: const GraphPlacement(x: 5, y: 0, width: 4, height: 1),
  );
  final books = [
    Book(
      bookId: skir.ResourceId(value: "book:earth"),
      title: "earth",
      icon: "mdi:earth",
      color: Colors.teal,
      tagIds: [lore.tagId],
    ),
    Book(
      bookId: skir.ResourceId(value: "book:mars"),
      title: "mars",
      icon: "mdi:rocket",
      color: Colors.teal,
      tagIds: [quest.tagId],
    ),
  ];

  return AuthoringFixtureApp(
    createDocument: () =>
        fixtureAuthoringDocument(books: books, tags: [lore, quest]),
    overrides: [
      organizationIdProvider.overrideWithValue(
        skir.recordId("organization:widgetbook"),
      ),
      realmIdProvider.overrideWithValue(skir.recordId("service:widgetbook")),
    ],
    child: InspectorScaffold(
      child: SelectedInspectorStory(
        selection: initiallySelected
            ? [for (final book in books) BookIdentifier(book.bookId)]
            : const [],
        child: const Center(child: _BookWidgetStory()),
      ),
    ),
  );
}

class _BookWidgetStory extends ConsumerWidget {
  const _BookWidgetStory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(workingBooksProvider);
    final tags = ref.watch(workingTagsProvider).value ?? const <Tag>[];
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
