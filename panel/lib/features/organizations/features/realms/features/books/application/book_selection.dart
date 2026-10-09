part of "books.dart";

/// Stable selectable identity for a book record.
///
/// Selection resolves this identity against the current organization and realm
/// session. It is therefore safe to retain as a key, but it is not a snapshot
/// of the book and must be resolved again after session state changes.
class BookIdentifier extends SelectableIdentifier
    implements ReferenceResourceDragData {
  const BookIdentifier(this.bookId);

  final skir.ResourceId bookId;

  @override
  String get id => bookId.id;

  @override
  Object get resourceId => bookId;

  @override
  skir.ResourceId get referenceId => bookId;

  @override
  List<ResolvedTypeRef> get referenceTypes => const [];

  /// Resolves the current book and builds its editor and navigation boundary.
  ///
  /// Missing organization or realm is a bad request, an unready session stays
  /// loading, and a completed session without this identity becomes a typed
  /// not found result. Tag data is required before the selection can expose
  /// the inspector collection.
  @override
  AsyncValue<Selectable> create(Ref ref) {
    final organization = ref.watch(organizationIdProvider);
    final realm = ref.watch(realmIdProvider);
    if (organization == null || realm == null) {
      return AsyncError(
        ApiException.badRequest("No realm selected"),
        StackTrace.current,
      );
    }
    final router = ref.watch(appRouterProvider);
    final scope = AuthoringScope(organizationId: organization, realmId: realm);
    final source = ref.watch(workingAuthoringDocumentProvider(scope));
    if (source.mapUnready<Selectable>() case final pending?) return pending;
    final document = source.requireValue;
    final workspace = ref.watch(authoringWorkspaceProvider(scope));
    final commands = ref.watch(authoredResourceCommandsProvider(scope));
    final resource = document.entry(bookId);
    if (resource == null) {
      return AsyncError(SelectableNotFoundException(this), StackTrace.current);
    }
    final book = Book.fromAuthoring(resource);
    return AsyncData(
      BookSelection(
        onOpen: () => router.navigate(routeFor(organization, realm)),
        onDelete: () async => workspace
            .edit(label: "Delete book", apply: (edit) => edit.delete(bookId))
            .requireAccepted(),
        id: this,
        book: book,
        workspace: workspace,
        commands: commands,
      ),
    );
  }

  @override
  int get hashCode => bookId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookIdentifier && other.bookId == bookId;

  @override
  String toString() => "BookIdentifier(bookId: $bookId)";

  /// Builds this book's editor route in the supplied organization and realm.
  BookRoute routeFor(skir.RecordId organization, skir.RecordId realm) {
    return BookRoute(
      organizationId: organization.id,
      realmId: realm.id,
      bookId: bookId.id,
    );
  }
}

/// Selection model shared by library navigation and the book inspector.
///
/// This read model carries the book from the current working revision.
/// The workspace owns shared edits and persistence. Opening selects one book
/// because navigation targets one book route.
class BookSelection extends InspectableSelectable<BookIdentifier> {
  const BookSelection({
    required this.onOpen,
    required this.onDelete,
    required this.id,
    required this.book,
    required this.workspace,
    required this.commands,
  });

  @override
  final BookIdentifier id;
  final Book book;
  final VoidCallback? onOpen;
  final Future<void> Function() onDelete;
  final AuthoringWorkspace workspace;
  final AuthoredResourceCommands commands;

  @override
  String get name => book.title;

  @override
  List<SelectionCapability> get capabilities => [
    if (onOpen case final open?)
      OpenSelectionCapability(onOpen: open, allowMultiSelect: false),
    DeleteSelectionCapability(onDelete: onDelete),
  ];

  @override
  InspectionContent buildInspection(EditorOwnerScope owners) =>
      InspectionContent(
        body: AuthoredResourceInspection(
          key: ValueKey((book.bookId, skir.PresentationRole.inspector)),
          resource: book.bookId,
          workspace: workspace,
          commands: commands,
        ),
      );
}
