import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:responsive_framework/responsive_framework.dart";
import "package:typewriter_panel/app/presentation/shell/panes.dart";
import "package:typewriter_panel/app/presentation/shortcuts/action_shortcuts.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/application/books.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/domain/selection.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/inspector.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/presentation/decorated_text_field.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/presentation/book.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/tags/application/tags.dart";
import "package:typewriter_panel/shared/ui/components/floating_button.dart";
import "package:typewriter_panel/shared/ui/components/icons.dart";
import "package:typewriter_panel/shared/ui/components/loading_button.dart";
import "package:typewriter_panel/shared/ui/components/page_heading.dart";
import "package:typewriter_panel/shared/ui/components/popups.dart";
import "package:typewriter_panel/shared/ui/components/section.dart";
import "package:typewriter_panel/shared/ui/components/vertical_clipper.dart";
import "package:typewriter_panel/shared/utilities/context.dart";
import "package:typewriter_panel/shared/utilities/riverpod.dart";
import "package:typewriter_panel/shared/utilities/snake_case_input_formatter.dart";

@RoutePage()
class LibraryPage extends HookConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final searchQuery = useState("");
    final filteredBooks = ref.watch(filteredBooksProvider(searchQuery.value));

    Future<void> handleCreateBook() async {
      final title = await _showBookTitleDialog(context);
      if (title == null || title.isEmpty) return;
      final newBook = await ref
          .read(booksProvider.notifier)
          .createBook(title: title);
      ref
          .read(selectionProvider.notifier)
          .select(BookIdentifier(newBook.bookId));
    }

    return Inspector(
      margin: EdgeInsets.only(top: 8, right: 8),
      child: Pane(
        id: "library",
        primary: true,
        borderRadius: BorderRadius.circular(12),
        margin: EdgeInsets.only(
          top: 8,
          left: 8,
          right: context.isMobile ? 8 : 0,
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
                    subtext:
                        "Browse books containing your quests, dialogues, and cinematics. Search by title or tag, organize related content, then open a book to continue editing its pages.",
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: DecoratedTextField(
                      focusNode: useFocusNode(),
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "Search books...",
                        prefixIcon: const Icon(Icons.search),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                      onChanged: (value) => searchQuery.value = value,
                    ),
                  ),
                  Expanded(
                    child: filteredBooks(
                      name: "filtered books",
                      builder: (books) {
                        if (books.isEmpty) {
                          return const Center(
                            child: Text(
                              "No books match your search",
                              style: TextStyle(fontSize: 18),
                            ),
                          );
                        }

                        return ClipPath(
                          clipper: VerticalClipper(additionalWidth: 100),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 16,
                            ),
                            child: ResponsiveGridView.builder(
                              gridDelegate: ResponsiveGridDelegate(
                                crossAxisExtent: bookWidth,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
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
                                  color: book.flutterColor,
                                  tags: book.tagIds
                                      .map(
                                        (tagId) =>
                                            ref.watch(tagProvider(tagId)).value,
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
      ),
    );
  }

  Future<String?> _showBookTitleDialog(BuildContext context) async {
    return showAdvancedDialog<String>(
      context: context,
      builder: (context) {
        return HookConsumer(
          builder: (context, ref, child) {
            final controller = useTextEditingController();
            final isValid = useListenableSelector(
              controller,
              () => controller.text.isNotEmpty,
            );
            final focusNode = useFocusNode();

            return AlertDialog(
              title: const Text("Create Book"),
              content: DecoratedTextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: DecoratedTextFieldAutoFocus.textField,
                decoration: const InputDecoration(hintText: "Enter book title"),
                inputFormatters: [SnakeCaseInputFormatter()],
                onSubmitted: (value) {
                  if (!isValid) return;
                  Navigator.of(context).pop(value);
                },
              ),
              actions: [
                TextButton.icon(
                  icon: const Icones(Fa6Solid.xmark),
                  label: const Text("Cancel"),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                LoadingButton.filledIcon(
                  onPressed: isValid
                      ? () => Navigator.of(context).pop(controller.text)
                      : null,
                  label: const Text("Create"),
                  icon: const Icon(Icons.add),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
