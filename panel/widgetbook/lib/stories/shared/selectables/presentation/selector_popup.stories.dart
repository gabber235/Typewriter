import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

/// Asynchronous states a selector can be opened from.
enum SelectorStoryState { loaded, loading, failed }

@widgetbook.UseCase(name: "Searchable sections", type: SelectorPopup)
Widget selectorPopupUseCase(BuildContext context) => SelectorPopupStory(
  state: context.knobs.object.dropdown(
    label: "Choices",
    options: SelectorStoryState.values,
    initialOption: SelectorStoryState.loaded,
    labelBuilder: (state) => state.name,
  ),
  longNames: context.knobs.boolean(label: "Long names", initialValue: false),
);

@widgetbook.UseCase(name: "Current selection", type: SelectorPopupWithSelection)
Widget selectorPopupWithSelectionUseCase(BuildContext context) =>
    SelectorPopupStory(
      withSelection: true,
      state: context.knobs.object.dropdown(
        label: "Choices",
        options: SelectorStoryState.values,
        initialOption: SelectorStoryState.loaded,
        labelBuilder: (state) => state.name,
      ),
      longNames: context.knobs.boolean(
        label: "Long names",
        initialValue: false,
      ),
    );

@widgetbook.UseCase(name: "Query input", type: SelectorSearchField)
Widget selectorSearchFieldUseCase(BuildContext context) {
  final width = context.knobs.double.slider(
    label: "Field width",
    initialValue: 320,
    min: 200,
    max: 480,
  );
  final hint = context.knobs.string(
    label: "Hint",
    initialValue: "Search books",
  );
  return FakeApp(
    child: SizedBox(
      width: width,
      child: HookBuilder(
        builder: (context) {
          final query = useState("");
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SelectorSearchField(searchQuery: query, hintText: hint),
              Text("Query: ${query.value}"),
            ],
          );
        },
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Section label", type: SelectorSectionHeader)
Widget selectorSectionHeaderUseCase(BuildContext context) => FakeApp(
  child: SelectorSectionHeader(
    title: context.knobs.string(label: "Title", initialValue: "Side quests"),
  ),
);

/// One book offered by the story selector.
final class _StoryBook {
  const _StoryBook(this.id, this.title, this.section, this.color);

  final String id;
  final String title;
  final String section;
  final Color color;
}

const _books = [
  _StoryBook("main_story", "The lost lantern", "Main story", Colors.amber),
  _StoryBook("harbor", "Harbor at dawn", "Main story", Colors.blue),
  _StoryBook("fishing", "Fishing contest", "Side quests", Colors.teal),
  _StoryBook("merchant", "The wandering merchant", "Side quests", Colors.red),
];

/// Selects a book through the shared popup and shows the chosen value outside
/// the popup so closing and selection can be checked separately.
class SelectorPopupStory extends HookWidget {
  const SelectorPopupStory({
    this.state = SelectorStoryState.loaded,
    this.longNames = false,
    this.withSelection = false,
    super.key,
  });

  final SelectorStoryState state;
  final bool longNames;
  final bool withSelection;

  @override
  Widget build(BuildContext context) {
    final selected = useState<_StoryBook?>(_books.first);
    final books = [
      for (final book in _books)
        if (longNames)
          _StoryBook(
            book.id,
            "${book.title} and the chapter that keeps going",
            book.section,
            book.color,
          )
        else
          book,
    ];
    final items = switch (state) {
      SelectorStoryState.loaded => AsyncData(books),
      SelectorStoryState.loading => const AsyncLoading<List<_StoryBook>>(),
      SelectorStoryState.failed => AsyncError<List<_StoryBook>>(
        "The Realm did not return its books",
        StackTrace.empty,
      ),
    };
    Widget button(_StoryBook? current) => Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Icon(Icons.menu_book, size: 16, color: current?.color),
        Text(current?.title ?? "Select a book"),
        const Icon(Icons.expand_more, size: 16),
      ],
    );
    Widget content(
      List<_StoryBook> choices,
      _StoryBook? current,
      void Function(_StoryBook) onSelect,
    ) => _BookMenu(
      books: choices,
      selected: current ?? selected.value,
      onSelect: (book) {
        selected.value = books.firstWhere((item) => item.id == book.id);
        onSelect(book);
      },
    );
    return FakeApp(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          if (withSelection)
            SelectorPopupWithSelection<_StoryBook>(
              itemsAsync: items,
              selectedAsync: AsyncData(
                books.firstWhereOrNull((book) => book.id == selected.value?.id),
              ),
              name: "books",
              buttonBuilder: button,
              contentBuilder: content,
            )
          else
            SelectorPopup<_StoryBook>(
              asyncValue: items,
              name: "books",
              buttonBuilder: (_) => button(selected.value),
              contentBuilder: content,
            ),
          Text("Selected book: ${selected.value?.title ?? "None"}"),
        ],
      ),
    );
  }
}

class _BookMenu extends HookWidget {
  const _BookMenu({
    required this.books,
    required this.selected,
    required this.onSelect,
  });

  final List<_StoryBook> books;
  final _StoryBook? selected;
  final void Function(_StoryBook) onSelect;

  @override
  Widget build(BuildContext context) {
    final query = useState("");
    final matches = books
        .where(
          (book) =>
              book.title.toLowerCase().contains(query.value.toLowerCase()),
        )
        .toList();
    final sections = matches.groupListsBy((book) => book.section);
    return SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelectorSearchField(searchQuery: query, hintText: "Search books"),
          if (matches.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("No books match"),
            ),
          for (final section in sections.entries) ...[
            SelectorSectionHeader(title: section.key),
            for (final book in section.value)
              ListTile(
                dense: true,
                selected: book.id == selected?.id,
                leading: Icon(Icons.menu_book, color: book.color),
                title: Text(book.title),
                onTap: () => onSelect(book),
              ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
