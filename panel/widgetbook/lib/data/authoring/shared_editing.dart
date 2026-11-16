import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

/// The Book whose [sharedEditingPages] stories edit together.
final sharedEditingBook = Book(
  bookId: skir.ResourceId(value: "book:the_harbor"),
  title: "The Harbor",
  icon: "material-symbols:book",
  color: const Color(0xff00796b),
  tagIds: const [],
);

/// Two pages of [sharedEditingBook] with different names, so editing them
/// together shows their name as mixed.
final sharedEditingPages = [
  Page(
    pageId: skir.ResourceId(value: "page:docks"),
    bookId: sharedEditingBook.bookId,
    name: "Docks",
    chapter: "act1",
  ),
  Page(
    pageId: skir.ResourceId(value: "page:lighthouse"),
    bookId: sharedEditingBook.bookId,
    name: "Lighthouse",
    chapter: "act1",
  ),
];
