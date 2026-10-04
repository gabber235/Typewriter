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
    final provider = authoringSessionProvider(organization, realm);
    final state = ref.watch(provider);
    if (state.failure case final failure?) {
      return AsyncError(failure, StackTrace.current);
    }
    final resource = state.resources[bookId];
    if (resource == null) {
      if (state.snapshot == null) return const AsyncLoading();
      return AsyncError(SelectableNotFoundException(this), StackTrace.current);
    }
    final draft = state.draft;
    final catalog = state.catalog;
    if (draft == null || catalog == null) return const AsyncLoading();
    final book = Book.fromAuthoring(resource);
    final session = ref.watch(provider.notifier);
    return AsyncData(
      BookSelection(
        onOpen: () => router.navigate(routeFor(organization, realm)),
        onDelete: () => session.deleteResource(
          bookId,
          conflictMessage: "The book changed before deletion",
        ),
        id: this,
        book: book,
        draft: draft,
        catalog: catalog,
        session: session,
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
/// The selection owns no canonical data. It carries the confirmed book and
/// revision used to create an editor snapshot, while [resource] owns loading,
/// draft reconciliation, commit, and disposal. Opening is deliberately
/// single select because navigation targets one book route.
class BookSelection extends InspectableSelectable<BookIdentifier> {
  const BookSelection({
    required this.onOpen,
    required this.onDelete,
    required this.id,
    required this.book,
    required this.draft,
    required this.catalog,
    required this.session,
  });

  @override
  final BookIdentifier id;
  final Book book;
  final VoidCallback? onOpen;
  final Future<void> Function() onDelete;
  final AuthoredDraft draft;
  final CheckedEditorCatalog catalog;
  final AuthoringSession session;

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
        header: InspectorHeader(
          id: book.bookId.value,
          name: book.title,
          color: book.color,
        ),
        body: AuthoredResourceInspection(
          key: ValueKey((book.bookId, skir.PresentationRole.inspector)),
          resource: book.bookId,
          draft: draft,
          catalog: catalog,
          commands: AuthoredResourceCommands(
            commit: session.commit,
            previewTypeArguments: session.previewTypeArguments,
            commitTypeArguments: session.commitTypeArguments,
            prepareCreation: session.prepareCreation,
            invokeCommand: session.invokeCommand,
            watchSearch: session.watchPresentationSearch,
            reload: session.refresh,
            openAutosave: session.openAutosave,
          ),
        ),
      );
}
