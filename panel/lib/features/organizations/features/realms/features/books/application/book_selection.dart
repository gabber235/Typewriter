part of "books.dart";

const bookInspectorTypeRef = ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "panel", name: "Book"),
  revision: 1,
);

const _bookInspectorPresentationId = PresentationId(
  namespace: "panel",
  name: "book.inspector",
);

final _bookInspectorType = TypeDefinition(
  id: bookInspectorTypeRef,
  kind: NominalTypeKind.concrete,
  defaultPresentationId: _bookInspectorPresentationId,
  representation: RecordType(
    fields: {
      "title": TypeField(name: "title", type: identifierStringType),
      "icon": TypeField(name: "icon", type: NamedType(standardTypeRefs.icon)),
      "color": TypeField(
        name: "color",
        type: NamedType(standardTypeRefs.color),
      ),
      "tags": TypeField(
        name: "tags",
        type: ListType(
          element: NamedType(
            standardTypeRefs.refTo(NamedType(tagInspectorTypeRef)),
          ),
          unique: true,
        ),
      ),
    },
  ),
);

final _bookInspectorCatalog = TypeCatalog([_bookInspectorType]);

final _bookInspectorPresentation = PresentationDefinition(
  id: _bookInspectorPresentationId,
  target: NamedType(bookInspectorTypeRef),
  root: PresentationNode(
    id: "book.inspector",
    element: ColumnElement(
      spacing: 16,
      crossAxisAlignment: PresentationCrossAxisAlignment.stretch,
      children: [
        PresentationNode(
          id: "book.title",
          element: TextInputElement(
            control: BoundControl(
              binding: _bookField("title"),
              label: "Title".asStringLiteral,
            ),
            multiline: false,
            inputFormatters: identifierInputFormats,
          ),
        ),
        PresentationNode(
          id: "book.icon",
          element: PolymorphicInputElement(
            control: BoundControl(
              binding: _bookField("icon"),
              label: "Icon".asStringLiteral,
            ),
            concreteTypes: [
              ConcreteTypePresentation(
                type: standardTypeRefs.iconifyIcon,
                label: "Iconify".asStringLiteral,
              ),
              ConcreteTypePresentation(
                type: standardTypeRefs.svgIcon,
                label: "SVG".asStringLiteral,
              ),
            ],
          ),
        ),
        PresentationNode(
          id: "book.color",
          element: ColorInputElement(
            control: BoundControl(
              binding: _bookField("color"),
              label: "Color".asStringLiteral,
            ),
          ),
        ),
        tagReferenceSearch(
          id: "book.tags",
          label: "Direct Tags",
          binding: _bookField("tags"),
        ),
        effectiveTagGraph(
          id: "book.effectiveTags",
          title: "Effective Tags",
          roots: _bookField("tags"),
        ),
      ],
    ),
  ),
);

class BookIdentifier extends SelectableIdentifier {
  const BookIdentifier(this.bookId);

  final skir.RecordId bookId;

  @override
  String get id => bookId.id;

  @override
  AsyncValue<Selectable> create(Ref ref) {
    final asyncBook = ref.watch(bookProvider(bookId));
    final tags = ref.watch(tagsProvider).value ?? const <Tag>[];
    return asyncBook.whenData((value) {
      if (value == null) throw SelectableNotFoundException(this);
      return BookSelection(
        ref: ref,
        id: this,
        book: value,
        tagCollection: tagPresentationCollection(tags),
      );
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
  BookSelection({
    required this.ref,
    required this.id,
    required this.book,
    required this.tagCollection,
  }) : _data = book.inspectorValue;

  @override
  final BookIdentifier id;
  final Book book;
  final Ref ref;
  final PresentationCollectionSource tagCollection;
  final RecordValue _data;

  @override
  String get name => book.title;

  @override
  EditorDocument get document => EditorDocument(
    rootType: NamedType(bookInspectorTypeRef),
    typeCatalog: _bookInspectorCatalog,
    confirmedValue: _data,
    revision: book.revision,
    mergePolicies: {DataPath.root.field("tags"): EditorMergePolicy.set},
    collections: [tagCollection],
    presentations: [_bookInspectorPresentation],
  );

  @override
  List<SelectionCapability> get capabilities => [];

  @override
  Widget? buildInspectorHeader() => BookHeader(
    id: book.bookId.id,
    name: book.title.formatted,
    color: book.color,
  );

  @override
  Future<TypedMutationResult> commit(EditorCommit commit) {
    final next = _bookFromInspectorValue(
      commit.rootValue,
      expectedRevision: commit.expectedRevision,
    );
    if (next == null) {
      return Future.value(
        TypedMutationResult.invalid([
          const TypeDiagnostic(
            code: TypeDiagnosticCode.invalidValue,
            message: "The Book inspector value is invalid",
          ),
        ]),
      );
    }
    return ref.read(booksProvider.notifier).updateBook(next);
  }

  @override
  int get hashCode => Object.hash(id, book);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookSelection && other.id == id && other.book == book;

  @override
  String toString() => "BookSelection(id: $id, book: $book)";

  Book? _bookFromInspectorValue(
    DataValue value, {
    required int expectedRevision,
  }) {
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
    final decodedColor = color.colorOrNull;
    final tagIds = tags.values
        .whereType<StringValue>()
        .map((tag) => recordId("tag:${tag.value}"))
        .toList();
    if (decodedColor == null || tagIds.length != tags.values.length) {
      return null;
    }
    final encodedIcon = switch (icon) {
      IconifyIconValue(:final value) => value,
      SvgIconValue(:final source) => source,
    };
    return book.copyWith(
      revision: expectedRevision,
      title: title.value,
      icon: encodedIcon,
      color: decodedColor,
      tagIds: tagIds,
    );
  }
}

BindingReference _bookField(String name) => BindingReference(
  bindingId: const BindingId(0),
  path: DataPath.root.field(name),
);

extension on Book {
  RecordValue get inspectorValue => RecordValue({
    "title": StringValue(title),
    "icon": IconValue.from(icon).typedValue,
    "color": color.integerValue,
    "tags": ListValue(tagIds.map((tagId) => StringValue(tagId.id)).toList()),
  });
}
