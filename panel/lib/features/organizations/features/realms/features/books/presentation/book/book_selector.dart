import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Lets the user switch from the active book to another book in the realm.
///
/// Projected books keep local metadata edits visible. The route remains the
/// selection authority, and choosing a book opens its root route.
class BookSelector extends HookConsumerWidget {
  const BookSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(projectedBooksProvider);
    final bookId = ref.watch(bookIdProvider);
    final selectedBookAsync = bookId == null
        ? const AsyncValue<Book?>.data(null)
        : ref.watch(projectedBookProvider(bookId));

    return SelectorPopupWithSelection<Book>(
      itemsAsync: booksAsync,
      selectedAsync: selectedBookAsync,
      name: "books",
      buttonBuilder: (selected) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icones(
            selected?.icon ?? "material-symbols:book-outline",
            size: 16,
            color: selected?.color ?? context.colors.contentDisabled,
          ),
          SizedBox(width: context.spacing.space2),
          Text(
            selected?.title.formatted ?? "Select Book",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      contentBuilder: (books, selected, onDismiss) => _BookMenuContent(
        books: books,
        selectedBook: selected,
        onDismiss: onDismiss,
      ),
    );
  }
}

/// Searchable menu body for the projected books in the active realm.
class _BookMenuContent extends HookConsumerWidget {
  const _BookMenuContent({
    required this.books,
    required this.selectedBook,
    required this.onDismiss,
  });

  final List<Book> books;
  final Book? selectedBook;
  final void Function(Book) onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = useState("");
    final lowercaseQuery = searchQuery.value.toLowerCase();
    final filteredBooks = books
        .where((book) => book.title.toLowerCase().contains(lowercaseQuery))
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SelectorSearchField(searchQuery: searchQuery, hintText: "Search books"),
        const SelectorSectionHeader(title: "Books"),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: filteredBooks.length,
            itemBuilder: (context, index) {
              final book = filteredBooks[index];
              return _BookMenuItem(
                book: book,
                isSelected: book.bookId == selectedBook?.bookId,
                onDismiss: onDismiss,
              );
            },
          ),
        ),
        SizedBox(height: context.spacing.space2),
      ],
    );
  }
}

/// Shows one book and navigates to its root route when selected.
class _BookMenuItem extends HookConsumerWidget {
  const _BookMenuItem({
    required this.book,
    required this.isSelected,
    required this.onDismiss,
  });

  final Book book;
  final bool isSelected;
  final void Function(Book) onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onColor = book.color.on(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.space2,
        vertical: 2,
      ),
      child: Material(
        borderRadius: context.shapes.mediumBorderRadius,
        color: isSelected ? book.color : null,
        child: Surface(
          color: isSelected ? book.color : Surface.colorOf(context),
          child: ListTile(
            dense: true,
            leading: Icones(
              book.icon,
              size: 20,
              color: isSelected ? onColor : book.color,
            ),
            title: Text(
              book.title.formatted,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontSize: 14, color: isSelected ? onColor : null),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: isSelected ? onColor : null,
            ),
            onTap: () {
              final organizationId = ref.read(organizationIdProvider);
              final realmId = ref.read(realmIdProvider);
              if (organizationId == null || realmId == null) return;
              ref
                  .read(appRouterProvider)
                  .navigate(
                    BookRoute(
                      organizationId: organizationId.id,
                      realmId: realmId.id,
                      bookId: book.bookId.id,
                    ),
                  );
              onDismiss(book);
            },
          ),
        ),
      ),
    );
  }
}
