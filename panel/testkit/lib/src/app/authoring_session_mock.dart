import "dart:async";

// ignore: implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "realm_catalog_fixture.dart";

class AuthoringSessionMock extends AuthoringSession {
  AuthoringSessionMock({AuthoringSessionState? initial, this.onApply})
    : initial =
          initial ??
          AuthoringSessionState(
            generation: skir.CatalogGeneration(
              value: realmFixtureGeneration.value,
            ),
            sequence: 1,
          );
  final AuthoringSessionState initial;
  final FutureOr<void> Function(List<skir.AuthoringOperation> operations)?
  onApply;

  @override
  Future<void> refresh() async {}

  @override
  AuthoringSelectionLease acquire(skir.GraphSelection selection) =>
      const _ReadyAuthoringScopeLease();

  @override
  AuthoringSessionState build(
    skir.RecordId organizationId,
    skir.RecordId realmId,
  ) => initial;

  @override
  Future<skir.ApplyAuthoringBatchResponse> apply(
    Iterable<skir.AuthoringOperation> operations, {
    String? batchId,
  }) async {
    await onApply?.call(List.unmodifiable(operations));
    state = state.copyWith(sequence: (state.sequence ?? 0) + 1);
    return skir.ApplyAuthoringBatchResponse.createApplied(
      generation: state.generation!,
      sequence: state.sequence!,
      batchId: batchId ?? "fixture",
      resources: const [],
      edges: const [],
      presentations: const [],
      compilationImpact: const [],
    );
  }
}

final class _ReadyAuthoringScopeLease implements AuthoringSelectionLease {
  const _ReadyAuthoringScopeLease();

  @override
  Future<void> get ready => Future.value();

  @override
  void release() {}
}

List<Override> authoringSessionMockOverrides({
  AuthoringSessionState? initial,
  Iterable<Book> books = const [],
  Iterable<Tag> tags = const [],
  bool includeCatalog = true,
  FutureOr<void> Function(List<skir.AuthoringOperation> operations)? onApply,
}) {
  assert(
    initial == null || (books.isEmpty && tags.isEmpty),
    "Use either an initial state or domain fixtures",
  );
  final state = initial ?? _fixtureState(books: books, tags: tags);
  return [
    authoringSessionProvider.overrideWith2(
      (_) => AuthoringSessionMock(initial: state, onApply: onApply),
    ),
    if (includeCatalog) ...[
      realmEditorCatalogProvider.overrideWith(
        (ref) => Stream.value(
          RealmEditorCatalogState.ready(authoringFixtureCatalog()),
        ),
      ),
      realmEditorCatalogLeaseProvider.overrideWith((ref, request) => null),
    ],
  ];
}

AuthoringSessionState _fixtureState({
  required Iterable<Book> books,
  required Iterable<Tag> tags,
}) {
  final generation = skir.CatalogGeneration(
    value: realmFixtureGeneration.value,
  );
  final codec = SkirEditorCodec(TypeRegistry(const TypeCatalog([])));
  const bookType = ResolvedTypeRef(
    id: QualifiedTypeId(namespace: "com.typewritermc.library", name: "Book"),
    revision: 1,
  );
  const tagType = ResolvedTypeRef(
    id: QualifiedTypeId(namespace: "com.typewritermc.library", name: "Tag"),
    revision: 1,
  );
  skir.AuthoringResource resource(
    skir.ResourceId id,
    ResourceDefinitionId definition,
    TypedValueEnvelope content,
  ) => skir.AuthoringResource(
    id: id,
    definition: definition.toWire(),
    content: skir.TypedValueEnvelope(
      rootType: codec.encodeType(content.rootType).valueOrNull!,
      rootValue: codec.encodeValue(content.rootValue).valueOrNull!,
    ),
  );

  final resources = <skir.ResourceId, skir.AuthoringResource>{
    for (final book in books)
      book.bookId: resource(
        book.bookId,
        CoreResourceDefinitionIds.book,
        book.authoringFixtureContent(bookType),
      ),
    for (final tag in tags)
      tag.tagId: resource(
        tag.tagId,
        CoreResourceDefinitionIds.tag,
        tag.authoringFixtureContent(tagType),
      ),
  };
  return AuthoringSessionState(
    generation: generation,
    sequence: 1,
    resources: resources,
  );
}

extension AuthoringFixtureBookContent on Book {
  TypedValueEnvelope authoringFixtureContent(ResolvedTypeRef rootType) =>
      TypedValueEnvelope(rootType: rootType, rootValue: inspectorValue);
}

extension AuthoringFixtureTagContent on Tag {
  TypedValueEnvelope authoringFixtureContent(ResolvedTypeRef rootType) =>
      TypedValueEnvelope(rootType: rootType, rootValue: inspectorValue);
}

RealmEditorCatalogSnapshot authoringFixtureCatalog() {
  const bookType = authoringFixtureBookType;
  const tagType = authoringFixtureTagType;
  const bookPresentation = PresentationId(
    namespace: "typewriter.core",
    name: "book.default",
  );
  const tagPresentation = PresentationId(
    namespace: "typewriter.core",
    name: "tag.default",
  );
  return receivedRealmEditorCatalog(
    definitions: [
      TypeDefinition(
        id: referenceResourceTypes.referenceable,
        kind: NominalTypeKind.openAbstract,
      ),
      TypeDefinition(
        id: bookType,
        kind: NominalTypeKind.concrete,
        parents: [referenceResourceTypes.referenceable],
        representation: RecordType(
          fields: {
            "title": TypeField(name: "title", type: StringType()),
            "icon": TypeField(
              name: "icon",
              type: NamedType(standardTypeRefs.icon),
            ),
            "color": TypeField(
              name: "color",
              type: NamedType(standardTypeRefs.color),
            ),
            "tags": TypeField(
              name: "tags",
              type: ListType(element: _tagReferenceType),
            ),
          },
        ),
        defaultPresentationId: bookPresentation,
        fieldMergePolicies: [
          FieldMergePolicy(
            path: DataPath.root.field("tags"),
            strategy: FieldMergeStrategy.setMembership,
          ),
        ],
      ),
      TypeDefinition(
        id: tagType,
        kind: NominalTypeKind.concrete,
        parents: [referenceResourceTypes.referenceable],
        representation: RecordType(
          fields: {
            "name": TypeField(name: "name", type: StringType()),
            "color": TypeField(
              name: "color",
              type: NamedType(standardTypeRefs.color),
            ),
            "parents": TypeField(
              name: "parents",
              type: ListType(element: _tagReferenceType),
            ),
            "placement": TypeField(
              name: "placement",
              type: RecordType(
                fields: {
                  "x": TypeField(
                    name: "x",
                    type: IntegerType(width: IntegerWidth.signed32),
                  ),
                  "y": TypeField(
                    name: "y",
                    type: IntegerType(width: IntegerWidth.signed32),
                  ),
                  "width": TypeField(
                    name: "width",
                    type: IntegerType(width: IntegerWidth.signed32),
                  ),
                  "height": TypeField(
                    name: "height",
                    type: IntegerType(width: IntegerWidth.signed32),
                  ),
                },
              ),
            ),
          },
        ),
        defaultPresentationId: tagPresentation,
        fieldMergePolicies: [
          FieldMergePolicy(
            path: DataPath.root.field("parents"),
            strategy: FieldMergeStrategy.setMembership,
          ),
        ],
      ),
      TypeDefinition(
        id: _tagCollectionRowType,
        kind: NominalTypeKind.concrete,
        representation: _tagCollectionRowRepresentation,
      ),
    ],
    presentations: {
      bookPresentation: _fixturePresentation(
        bookPresentation,
        const NamedType(bookType),
        const [
          ("title", "Title"),
          ("icon", "Icon"),
          ("color", "Color"),
          ("tags", "Direct Tags"),
        ],
        graphField: "tags",
        graphLabel: "Effective Tags",
      ),
      tagPresentation: _fixturePresentation(
        tagPresentation,
        const NamedType(tagType),
        const [
          ("name", "Name"),
          ("color", "Color"),
          ("parents", "Direct Parents"),
          ("placement", "Placement"),
        ],
        graphField: "parents",
        graphLabel: "Inheritance",
      ),
    },
    resourceDefinitions: {
      CoreResourceDefinitionIds.book: RealmResourceDefinition(
        id: CoreResourceDefinitionIds.book,
        acceptedRoot: const NamedType(bookType),
      ),
      CoreResourceDefinitionIds.tag: RealmResourceDefinition(
        id: CoreResourceDefinitionIds.tag,
        acceptedRoot: const NamedType(tagType),
      ),
    },
    collectionProjections: {
      authoringTagCollectionSourceId: RealmCollectionProjectionDefinition(
        sourceId: authoringTagCollectionSourceId,
        definitions: const {CoreResourceDefinitionIds.tag},
        assignableTo: const NamedType(tagType),
        rowType: _tagCollectionRowType,
        fields: [
          const RealmCollectionProjectionField(
            target: DataPath([FieldPathSegment("key")]),
            source: RealmCollectionResourceId(),
          ),
          const RealmCollectionProjectionField(
            target: DataPath([FieldPathSegment("name")]),
            source: RealmCollectionContentPath(
              DataPath([FieldPathSegment("name")]),
            ),
          ),
          const RealmCollectionProjectionField(
            target: DataPath([FieldPathSegment("color")]),
            source: RealmCollectionContentPath(
              DataPath([FieldPathSegment("color")]),
            ),
          ),
          const RealmCollectionProjectionField(
            target: DataPath([FieldPathSegment("parents")]),
            source: RealmCollectionContentPath(
              DataPath([FieldPathSegment("parents")]),
            ),
          ),
          const RealmCollectionProjectionField(
            target: DataPath([FieldPathSegment("selectable")]),
            source: RealmCollectionLiteral(BooleanValue(true)),
          ),
        ],
      ),
    },
  );
}

const authoringFixtureBookType = ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "com.typewritermc.library", name: "Book"),
  revision: 1,
);
const authoringFixtureTagType = ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "com.typewritermc.library", name: "Tag"),
  revision: 1,
);
const authoringFixtureTagPresentationId = PresentationId(
  namespace: "typewriter.core",
  name: "tag.default",
);

PresentationCollectionSource authoringFixtureTagCollection(
  Iterable<Tag> tags,
) => LocalPresentationCollectionSource(
  id: authoringTagCollectionSourceId,
  schema: _tagSchema,
  rows: [
    for (final tag in tags)
      RecordValue({
        "key": ReferenceValue(tag.tagId),
        "name": StringValue(tag.name),
        "color": tag.color.asValue,
        "parents": ListValue(tag.parentIds.map(ReferenceValue.new).toList()),
        "selectable": const BooleanValue(true),
      }),
  ],
  registry: TypeRegistry(authoringFixtureCatalog().catalog),
);

PresentationDefinition _fixturePresentation(
  PresentationId id,
  TypeExpression target,
  List<(String, String)> fields, {
  required String graphField,
  required String graphLabel,
}) => PresentationDefinition(
  id: id,
  inputs: [
    PresentationInputParameter(
      id: const BindingId(0),
      name: "content",
      type: target,
      access: PresentationInputAccess.edit,
    ),
  ],
  primaryInput: const BindingId(0),
  collections: {const PresentationCollectionSourceId("realm.tags"): _tagSchema},
  root: PresentationNode(
    id: "${id.name}.root",
    element: ColumnElement(
      children: [
        for (final (field, label) in fields)
          PresentationAxisChild.fixed(
            PresentationNode(
              id: "${id.name}.$field",
              header: PresentationHeader(
                title: label.asStringLiteral.asHeaderTitle,
                initiallyExpanded: field == graphField,
              ),
              element: SectionElement(
                child: PresentationNode(
                  id: "${id.name}.$field.editor",
                  element: DefaultPresentationElement(
                    binding: BindingReference(
                      bindingId: const BindingId(0),
                      path: DataPath.root.field(field),
                    ),
                  ),
                ),
              ),
            ),
          ),
        PresentationAxisChild.fixed(
          _fixtureTagGraph(
            "${id.name}.graph",
            graphLabel,
            BindingReference(
              bindingId: const BindingId(0),
              path: DataPath.root.field(graphField),
            ),
          ),
        ),
      ],
    ),
  ),
);

PresentationNode _fixtureTagGraph(
  String id,
  String label,
  BindingReference roots,
) => PresentationNode(
  id: "$id.section",
  header: PresentationHeader(
    title: label.asStringLiteral.asHeaderTitle,
    initiallyExpanded: true,
  ),
  element: SectionElement(
    child: PresentationNode(
      id: id,
      element: CollectionGraphElement(
        sourceId: const PresentationCollectionSourceId("realm.tags"),
        roots: roots,
        rootSequence: SequencePresentation(
          item: PresentationNode(
            id: "$id.root",
            element: PresentationSlotElement(slotId: "$id.children"),
          ),
          layout: PresentationSequenceLayout.children(
            const PresentationChildrenLayout.column(spacing: 8),
          ),
        ),
        relation: const PresentationCollectionRelationId("inherits"),
        direction: CollectionGraphDirection.forward,
        node: PresentationNode(
          id: "$id.row",
          element: ColumnElement(
            children: [
              PresentationAxisChild.fixed(
                PresentationNode(
                  id: "$id.row.label",
                  element: TextElement(
                    TypedExpression(
                      resultType: const StringType(),
                      expression: BindingExpression(
                        BindingReference(
                          bindingId: const BindingId(40),
                          path: DataPath.root.field("name"),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              PresentationAxisChild.fixed(
                PresentationNode(
                  id: "$id.row.children",
                  element: PresentationSlotElement(slotId: "$id.children"),
                ),
              ),
            ],
          ),
        ),
        childrenBindingId: const BindingId(41),
        childBindingId: const BindingId(42),
        children: SequencePresentation(
          item: PresentationNode(
            id: "$id.child",
            element: PresentationSlotElement(slotId: "$id.children"),
          ),
          layout: PresentationSequenceLayout.children(
            const PresentationChildrenLayout.column(spacing: 8),
          ),
        ),
      ),
    ),
  ),
);

const _tagCollectionRowType = ResolvedTypeRef(
  id: QualifiedTypeId(
    namespace: "typewriter.fixture",
    name: "TagCollectionRow",
  ),
  revision: 1,
);
final _tagReferenceType = ReferenceType(
  target: const ResolvedTypeRef(
    id: QualifiedTypeId(namespace: "com.typewritermc.library", name: "Tag"),
    revision: 1,
  ),
);
final _tagCollectionRowRepresentation = RecordType(
  fields: {
    "key": TypeField(name: "key", type: _tagReferenceType),
    "name": const TypeField(name: "name", type: StringType()),
    "color": const TypeField(
      name: "color",
      type: IntegerType(width: IntegerWidth.unsigned32),
    ),
    "parents": TypeField(
      name: "parents",
      type: ListType(element: _tagReferenceType),
    ),
    "selectable": const TypeField(name: "selectable", type: BooleanType()),
  },
);
final _tagSchema = PresentationCollectionSchema(
  rowType: const NamedType(_tagCollectionRowType),
  rowBindingId: const BindingId(40),
  key: TypedExpression(
    resultType: _tagReferenceType,
    expression: BindingExpression(
      BindingReference(
        bindingId: const BindingId(40),
        path: DataPath.root.field("key"),
      ),
    ),
  ),
  selectability: TypedExpression(
    resultType: const BooleanType(),
    expression: BindingExpression(
      BindingReference(
        bindingId: const BindingId(40),
        path: DataPath.root.field("selectable"),
      ),
    ),
  ),
  relations: [
    PresentationCollectionRelation(
      id: const PresentationCollectionRelationId("inherits"),
      targets: TypedExpression(
        resultType: ListType(element: _tagReferenceType),
        expression: BindingExpression(
          BindingReference(
            bindingId: const BindingId(40),
            path: DataPath.root.field("parents"),
          ),
        ),
      ),
    ),
  ],
);
