import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

void main() {
  test("book and page selectors resolve a page inside the named Book", () {
    final document = _document();

    expect(
      _query(book: "Other", page: "Intro").resolvePage(document),
      _otherPage.pageId,
    );
    expect(_query(book: "Other").resolveBook(document), _otherBook.bookId);
    expect(
      _query(book: "Missing", page: "Intro").resolvePage(document),
      isNull,
    );
  });

  test("ambiguous selectors and titles do not choose a destination", () {
    final duplicate = _otherBook.copyWith(
      bookId: skir.ResourceId(value: "duplicate"),
    );
    final document = _document(extraBooks: [duplicate]);

    expect(_query(book: "Other").resolveBook(document), isNull);
    expect(_query(page: "Intro").resolvePage(document), isNull);
    expect(
      SearchQueryContext(
        normalizedQuery: "",
        selectors: const [
          SearchParsedSelector(
            selectorId: authoringPageSelectorId,
            key: "page:",
            value: "Intro",
          ),
          SearchParsedSelector(
            selectorId: authoringPageSelectorId,
            key: "page:",
            value: "Other",
          ),
        ],
      ).resolvePage(document),
      isNull,
    );
  });

  test("a Book selector constrains a new page to that Book", () {
    final document = _document();
    final page = document.catalog.beginSelection(fixtureResourceType("page"));

    final context = _query(book: "Current").creationContext(
      document: document,
      configuration: page,
      preferredResources: const [],
    );

    expect(context.constraints, [
      CreationReferenceConstraint(
        route: [libraryPageBookEndpoint],
        target: _currentBook.bookId,
      ),
    ]);
  });
}

AuthoringDocument _document({List<Book> extraBooks = const []}) =>
    fixtureAuthoringDocument(
      realm: true,
      books: [_currentBook, _otherBook, ...extraBooks],
      pages: [_currentPage, _otherPage],
    );

SearchQueryContext _query({String? book, String? page}) => SearchQueryContext(
  normalizedQuery: "",
  selectors: [
    if (book != null)
      SearchParsedSelector(selectorId: "book", key: "book:", value: book),
    if (page != null)
      SearchParsedSelector(selectorId: "page", key: "page:", value: page),
  ],
);

final _currentBook = Book(
  bookId: skir.ResourceId(value: "current"),
  title: "Current",
  icon: "mdi:book",
  color: Colors.blue,
);
final _otherBook = Book(
  bookId: skir.ResourceId(value: "other"),
  title: "Other",
  icon: "mdi:book",
  color: Colors.green,
);
final _currentPage = Page(
  pageId: skir.ResourceId(value: "current:intro"),
  bookId: _currentBook.bookId,
  name: "Intro",
);
final _otherPage = Page(
  pageId: skir.ResourceId(value: "other:intro"),
  bookId: _otherBook.bookId,
  name: "Intro",
);
