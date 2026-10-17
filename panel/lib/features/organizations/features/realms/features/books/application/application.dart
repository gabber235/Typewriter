/// Application contracts for the realm library of books.
///
/// This library owns the translation between the realm authoring session and
/// the editor and selection systems. The authoring session is authoritative.
/// Providers expose confirmed values and local editor projections separately;
/// commands submit conditional wire operations, while selections connect a
/// book to navigation, inspection, and resource lifecycle management.
library;

export "book_authoring_navigation.dart";
export "books.dart";
