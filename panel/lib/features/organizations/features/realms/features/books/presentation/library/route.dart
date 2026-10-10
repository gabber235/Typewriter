import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Book library route.
///
/// The library reads the shared working book collection, applies local search for
/// title and tag projections, and delegates creation to the generic resource creation
/// boundary. Selection is updated after creation so the new book follows the
/// shared selectable and editor flow.
@RoutePage()
class LibraryPage extends HookConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(selectedAuthoringScopeProvider);
    final searchController = useTextEditingController();
    final searchQuery = useState("");
    final filteredBooks = ref.watch(filteredBooksProvider(searchQuery.value));
    final document = ref.watch(selectedWorkingAuthoringDocumentProvider).value;
    final definitionId = coreBookResourceDefinition;
    final definition = document?.catalog.snapshot.resourceDefinitions
        .where((candidate) => candidate.id == definitionId)
        .firstOrNull;
    final selection = definition == null
        ? null
        : document?.catalog.beginSelection(definition.root);
    final canCreate =
        scope != null &&
        selection != null &&
        selection != skir.TypeSelection.unknown;

    Future<void> handleCreateBook() async {
      final current = definition == null
          ? null
          : ref
                .read(selectedWorkingAuthoringDocumentProvider)
                .value
                ?.catalog
                .beginSelection(definition.root);
      if (current == null || current == skir.TypeSelection.unknown) {
        throw StateError("Book creation is unavailable");
      }
      final created = await ref
          .read(resourceCreationProvider(scope!))
          .create(
            context: context,
            request: ResourceCreationRequest(
              definition: definitionId,
              configuration: current,
            ),
          );
      if (created == null) return;
      ref
          .read(selectionProvider.notifier)
          .select(
            AuthoringResourceIdentifier.inScope(created.scope, created.id),
          );
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
              onInvoke: canCreate ? (_) => handleCreateBook() : null,
            ),
          ],
          child: FloatingButton(
            icon: const Icon(Icons.add),
            onPressed: canCreate ? handleCreateBook : null,
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
                          onPressed: canCreate ? handleCreateBook : null,
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
                                          .watch(workingTagProvider(tagId))
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
