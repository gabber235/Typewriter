import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:responsive_framework/responsive_framework.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Book library route.
///
/// The library reads the canonical book collection, applies local search for
/// title and tag projections, and delegates creation to the books application
/// provider. Selection is updated after creation so the new book follows the
/// shared selectable and editor flow.
@RoutePage()
class LibraryPage extends HookConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final searchQuery = useState("");
    final filteredBooks = ref.watch(filteredBooksProvider(searchQuery.value));

    Future<void> handleCreateBook() async {
      final catalog = ref.read(realmEditorCatalogProvider).value?.snapshot;
      final root = catalog
          ?.creationSlots[CoreAuthoringCreationSlotIds.book]
          ?.concreteRoots
          .singleOrNull;
      if (root == null) throw StateError("Book creation is unavailable");
      final created = await ref
          .read(resourceCreationProvider)
          .create(
            context: context,
            request: ResourceCreationRequest(
              slot: CoreAuthoringCreationSlotIds.book,
              title: "Create Book",
              concreteRoot: root,
              partial: RecordValue({}),
            ),
          );
      if (created == null) return;
      ref.read(selectionProvider.notifier).select(BookIdentifier(created.id));
    }

    return Pane(
      id: "library",
      primary: true,
      borderRadius: context.shapes.largeBorderRadius,
      margin: EdgeInsets.only(
        top: context.spacing.space2,
        left: context.spacing.space2,
        right: context.isMobile ? context.spacing.space2 : 0,
      ),
      child: Section(
        margin: EdgeInsets.zero,
        child: ManagedActionSet(
          shortcuts: [
            ActionShortcut(
              id: "library.create",
              label: "Create Book",
              description: "Create a new book",
              activators: const [
                SingleActivator(LogicalKeyboardKey.keyN),
                SingleActivator(LogicalKeyboardKey.keyA),
                SingleActivator(LogicalKeyboardKey.numpadAdd),
              ],
              priority: 100,
              icon: const Icon(Icons.add),
              onInvoke: (_) => handleCreateBook(),
            ),
          ],
          child: FloatingButton(
            icon: const Icon(Icons.add),
            onPressed: handleCreateBook,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageHeading(
                  title: "Library",
                  subtext: "Browse books containing your quests, dialogues, and cinematics. Search by title or tag, organize related content, then open a book to continue editing its pages.",
                ),
                Padding(
                  padding: EdgeInsets.all(context.spacing.space4),
                  child: EditorTextField(
                    focusNode: useFocusNode(),
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search books...",
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (value) => searchQuery.value = value,
                  ),
                ),
                Expanded(
                  child: filteredBooks(
                    name: "filtered books",
                    builder: (books) {
                      if (books.isEmpty) {
                        return EmptyScreen(
                          title: searchQuery.value.isEmpty
                              ? "Insert your favorite story here"
                              : "No books match your search",
                          buttonText: "Create Book",
                          onPressed: handleCreateBook,
                        );
                      }

                      return ClipPath(
                        clipper: VerticalClipper(additionalWidth: 100),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.spacing.space2,
                            vertical: context.spacing.space4,
                          ),
                          child: ResponsiveGridView.builder(
                            primary: true,
                            gridDelegate: ResponsiveGridDelegate(
                              crossAxisExtent: bookWidth,
                              mainAxisSpacing: context.spacing.space4,
                              crossAxisSpacing: context.spacing.space4,
                              childAspectRatio: bookAspectRatio,
                            ),
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            itemCount: books.length,
                            itemBuilder: (context, index) {
                              final book = books[index];
                              return BookWidget(
                                id: book.bookId,
                                title: book.title,
                                icon: Icones(book.icon),
                                color: book.color,
                                tags: book.tagIds
                                    .map(
                                      (tagId) => ref
                                          .watch(projectedTagProvider(tagId))
                                          .value,
                                    )
                                    .nonNulls
                                    .toList(),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
