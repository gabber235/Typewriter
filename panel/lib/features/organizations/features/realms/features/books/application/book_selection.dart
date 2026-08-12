part of "books.dart";

const _bookInspectorType = TypeDefinition(
  id: ResolvedTypeRef(
    id: QualifiedTypeId(namespace: "panel", name: "Book"),
    revision: 1,
  ),
  kind: NominalTypeKind.concrete,
  representation: RecordType(
    fields: {"title": TypeField(name: "title", type: StringType())},
  ),
);

const _bookInspectorCatalog = TypeCatalog([_bookInspectorType]);

class BookIdentifier extends SelectableIdentifier {
  const BookIdentifier(this.bookId);

  final skir.RecordId bookId;

  @override
  String get id => bookId.id;

  @override
  AsyncValue<Selectable> create(Ref ref) {
    final asyncBook = ref.watch(bookProvider(bookId));
    return asyncBook.whenData((value) {
      if (value == null) throw SelectableNotFoundException(this);
      return BookSelection(ref: ref, id: this, book: value);
    });
  }

  @override
  int get hashCode => bookId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookIdentifier && other.bookId == bookId;

  @override
  String toString() => "BookIdentifier(bookId: $bookId)";
}

class BookSelection extends InspectableSelectable<BookIdentifier> {
  BookSelection({required this.ref, required this.id, required this.book})
    : _data = RecordValue({"title": StringValue(book.title)});

  @override
  final BookIdentifier id;
  final Book book;
  final Ref ref;
  final RecordValue _data;

  @override
  String get name => book.title;

  @override
  ResolvedTypeRef get rootType => _bookInspectorType.id;

  @override
  TypeCatalog get typeCatalog => _bookInspectorCatalog;

  @override
  List<SelectionCapability> get capabilities => [];

  @override
  Widget? buildInspectorHeader() => BookHeader(
    id: book.bookId.id,
    name: book.title.formatted,
    color: book.color,
  );

  @override
  EditorValue value(DataPath path) => _data.readEditorValue(path);

  @override
  EditorMutationResult update(DataPath path, DataValue value) {
    final result = validateUpdate(path, value);
    if (result is! AppliedEditorMutation || value is! StringValue) {
      return result;
    }
    ref
        .read(booksProvider.notifier)
        .updateBook(book.copyWith(title: value.value));
    return result;
  }

  @override
  int get hashCode => Object.hash(id, book);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookSelection && other.id == id && other.book == book;

  @override
  String toString() => "BookSelection(id: $id, book: $book)";
}
