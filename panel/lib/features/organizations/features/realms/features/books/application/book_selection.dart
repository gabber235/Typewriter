part of "books.dart";

/// Stable selectable identity for a book record.
///
/// Selection resolves this identity against the current organization and realm
/// session. It is therefore safe to retain as a key, but it is not a snapshot
/// of the book and must be resolved again after session state changes.
class BookIdentifier extends SelectableIdentifier
    implements ReferenceResourceDragData {
  const BookIdentifier(this.bookId);

  final skir.RecordId bookId;

  @override
  String get id => bookId.id;

  @override
  Object get resourceId => bookId;

  @override
  skir.RecordId get referenceId => bookId;

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
    final repository = ref
        .watch(resourceRepositoriesProvider)
        .authoring(organization, realm);
    final router = ref.watch(appRouterProvider);
    final session = ref.watch(authoringSessionProvider(organization, realm));
    final bookValue = session.bookEditorValue(bookId);
    if (bookValue == null) {
      if (session.sequence == null) return const AsyncLoading();
      return AsyncError(SelectableNotFoundException(this), StackTrace.current);
    }
    final book = bookValue.value;

    final tagsAsync = ref.watch(projectedTagsProvider);
    if (tagsAsync.mapUnready<Selectable>() case final value?) return value;
    final tags = tagsAsync.requireValue;
    return AsyncData(
      BookSelection(
        resource: BookEditorResource(repository, bookId),
        onOpen: () => router.navigate(routeFor(organization, realm)),
        id: this,
        book: book,
        revision: bookValue.revision,
        tagCollection: tags.presentationCollection(),
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
class BookSelection extends EditableSelectable<BookIdentifier> {
  const BookSelection({
    required this.resource,
    required this.onOpen,
    required this.id,
    required this.book,
    required this.revision,
    required this.tagCollection,
  });

  @override
  final BookIdentifier id;
  final Book book;
  final int revision;
  @override
  final EditableResource resource;
  final VoidCallback? onOpen;

  final PresentationCollectionSource tagCollection;

  @override
  MultiInspectionDefinition get multiInspection =>
      const BookMultiInspectionDefinition();

  @override
  String get name => book.title;

  @override
  List<PresentationDefinition> get presentations => [
    _bookInspectorPresentation,
  ];
  @override
  List<PresentationCollectionSource> get collections => [tagCollection];

  @override
  EditorSnapshot get snapshot => BookEditorSnapshot(book, revision);
  @override
  List<SelectionCapability> get capabilities => [
    if (onOpen case final open?)
      OpenSelectionCapability(onOpen: open, allowMultiSelect: false),
  ];

  @override
  Widget? buildInspectorHeader(EditOwner owner) => ManagedInspectorHeader(
    id: book.bookId.id,
    owner: owner,
    fallbackName: book.title.formatted,
    fallbackColor: book.color,
    nameField: "title",
  );
}

BindingReference _bookField(String name) => BindingReference(
  bindingId: const BindingId(0),
  path: DataPath.root.field(name),
);

/// Encodes and decodes the book fields understood by the inspector.
///
/// Decoding is intentionally strict at the editor boundary. Invalid shape,
/// empty required text, invalid color, or non string tag entries returns null;
/// [projected] then falls back to the last valid book rather than exposing a
/// malformed local draft to consumers.
extension BookInspectorValue on Book {
  RecordValue get inspectorValue => RecordValue({
    "title": title.asValue,
    "icon": IconValue.from(icon).typedValue,
    "color": color.asValue,
    "tags": ListValue(tagIds.map(ReferenceValue.new).toList()),
  });

  /// Reconstructs a book only when the complete inspector record is valid.
  Book? withInspectorValue(DataValue value) {
    if (value is! RecordValue) return null;
    final title = value.fields["title"];
    final icon = value.fields["icon"]?.iconValueOrNull;
    final color = value.fields["color"];
    final tags = value.fields["tags"];
    if (title is! StringValue ||
        title.value.trim().isEmpty ||
        icon == null ||
        color is! IntegerValue ||
        tags is! ListValue) {
      return null;
    }
    final decodedColor = color.asColorOrNull;
    final tagIds = tags.values
        .whereType<ReferenceValue>()
        .map((tag) => tag.id)
        .toList();
    if (decodedColor == null || tagIds.length != tags.values.length) {
      return null;
    }
    final encodedIcon = switch (icon) {
      IconifyIconValue(:final value) => value,
      SvgIconValue(:final source) => source,
    };
    return copyWith(
      title: title.value,
      icon: encodedIcon,
      color: decodedColor,
      tagIds: tagIds,
    );
  }

  /// Applies a local draft while preserving this value on decode failure.
  Book projected(LocalEditorValue? local) {
    if (local == null) return this;
    return withInspectorValue(local.projectOnto(inspectorValue)) ?? this;
  }
}
