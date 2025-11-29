import "package:collection/collection.dart";
import "package:collection_ext/all.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/models/communicator.dart";
import "package:typewriter/models/entry.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/models/extension.dart";
import "package:typewriter/models/page.dart";
import "package:typewriter/utils/extensions.dart";

part "book.freezed.dart";

final bookProvider = StateNotifierProvider<BookNotifier, Book>(
  (ref) =>
      BookNotifier(const Book(name: "", extensions: [], pages: []), ref: ref),
  name: "bookProvider",
);

@freezed
class Book with _$Book {
  const factory Book({
    required String name,
    required List<Extension> extensions,
    required List<Page> pages,
  }) = _Book;
}

class BookNotifier extends StateNotifier<Book> {
  BookNotifier(super.state, {required this.ref});
  final Ref<Book> ref;

  Book get book => state;
  set book(Book book) => state = book;

  @override
  bool updateShouldNotify(Book old, Book current) => true;

  /// Creates a new page.
  Future<Page> createPage(
    String name, [
    PageType type = PageType.static,
    String chapter = "",
    int priority = 0,
  ]) async {
    final page = Page(
      id: getRandomString(),
      pageName: name,
      type: type,
      chapter: chapter,
      priority: priority,
    );
    await ref.read(communicatorProvider).createPage(page);
    state = state.copyWith(
      pages: [...state.pages, page],
    );
    return page;
  }

  /// Inserts a page. If the page already exists, it will be replaced.
  void insertPage(Page page) {
    state = state.copyWith(
      pages: state.pages.map((p) => p.id == page.id ? page : p).toList(),
    );
  }

  /// Rename a page.
  /// If the page does not exist, it will be added.
  Future<void> renamePage(String pageId, String newName) async {
    final page = state.pages.firstWhereOrNull((p) => p.id == pageId);
    if (page == null) return;
    await ref.read(communicatorProvider).renamePage(pageId, newName);
    syncRenamePage(pageId, newName);
  }

  /// Deletes a page.
  Future<void> deletePage(String pageId) async {
    await ref.read(communicatorProvider).deletePage(pageId);
    syncDeletePage(pageId);
  }

  ///Moves an entry from one page to another.
  Future<void> moveEntry(
    String entryId,
    String fromPageId,
    String toPageId,
  ) async {
    if (fromPageId == toPageId) return;
    await ref
        .read(communicatorProvider)
        .moveEntry(entryId, fromPageId, toPageId);
    syncMoveEntry(entryId, fromPageId, toPageId);
  }

  /// Reloads the book from the server.
  Future<void> reload() async {
    return ref.read(communicatorProvider).fetchBook();
  }

  /// Only for internal use.
  void syncRenamePage(String pageId, String newName) {
    final page = state.pages.firstWhereOrNull((p) => p.id == pageId);
    if (page == null) return;
    insertPage(page.copyWith(pageName: newName));
  }

  /// Only for internal use.
  void syncDeletePage(String pageId) {
    state = state.copyWith(
      pages: state.pages
          .where((p) => p.id != pageId)
          .map((p) => _removePageReferences(p, pageId))
          .toList(),
    );
  }

  /// Only for internal use.
  void syncMoveEntry(String entryId, String fromPageId, String toPageId) {
    final from = state.pages.firstWhereOrNull((p) => p.id == fromPageId);
    final to = state.pages.firstWhereOrNull((p) => p.id == toPageId);
    if (from == null || to == null) return;

    final entry = from.entries.firstWhereOrNull((e) => e.id == entryId);
    if (entry == null) return;
    state = state.copyWith(
      pages: [
        ...state.pages.where((p) => p.id != fromPageId && p.id != toPageId),
        from.copyWith(
          entries: from.entries.where((e) => e.id != entryId).toList(),
        ),
        to.copyWith(entries: [...to.entries, entry]),
      ],
    );
  }

  /// Remove page references from entries.
  Page _removePageReferences(Page page, String targetPageId) {
    final newEntries = page.entries
        .map(
          (entry) => _removedReferencesFromEntry(page, entry, targetPageId),
        )
        .toList();
    return page.copyWith(entries: newEntries);
  }

  /// When a page is renamed or deleted, all references to it must be updated.
  Entry _removedReferencesFromEntry(
    Page page,
    Entry entry,
    String targetPageId,
  ) {
    final referenceEntryPaths = state.extensions
            .flatMap((extension) => extension.entries)
            .firstWhereOrNull((blueprint) => blueprint.id == entry.blueprintId)
            ?.fieldsWithModifier("page")
            .keys
            .toList() ??
        [];

    final referenceEntryIds = referenceEntryPaths
        .expand((path) => entry.getAll(path))
        .whereType<String>()
        .toList();
    if (!referenceEntryIds.contains(targetPageId)) {
      return entry;
    }

    final newEntry = referenceEntryPaths.fold(
      entry,
      (previousEntry, path) => previousEntry.copyMapped(
        path,
        (value) => value == targetPageId ? null : value,
      ),
    );

    ref.read(communicatorProvider).updateEntireEntry(page.id, newEntry);

    return newEntry;
  }
}
