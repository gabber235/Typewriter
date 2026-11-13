import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  group("offersFor", () {
    test("uses the most specific destination that has offers", () {
      final document = _document;
      final index = dropCandidateIndex(
        _scope,
        [_page1],
        destinations: {
          fixtureOperationId("MoveToOwner"): [_bookB],
        },
      );
      expect(
        index
            .offersFor([
              DropDestination.resource(_bookA),
              DropDestination.resource(_bookB),
            ], document)
            .map((offer) => offer.label),
        ["Move to"],
      );
      expect(
        index.offersFor([
          DropDestination.resource(_bookB),
          DropDestination.regroup(_chapter, "act2"),
        ], document).single,
        isA<OperationDropOffer>(),
      );
    });

    test("sorts offers by group, then order", () {
      final document = _document;
      final index = dropCandidateIndex(
        _scope,
        [_bookB],
        destinations: {
          fixtureOperationId("LinkWith"): [_bookA],
          fixtureOperationId("MoveToOwner"): [_bookA],
          fixtureOperationId("Annotate"): [_bookA],
        },
      );
      expect(
        index
            .offersFor([DropDestination.resource(_bookA)], document)
            .map((offer) => offer.label),
        ["Annotate", "Move to", "Link with"],
      );
    });

    test("never offers a dragged resource as its own destination", () {
      final document = _document;
      final index = dropCandidateIndex(
        _scope,
        [_bookA],
        destinations: {
          fixtureOperationId("LinkWith"): [_bookA],
        },
      );
      expect(
        index.offersFor([DropDestination.resource(_bookA)], document),
        isEmpty,
      );
    });

    test("writes the drop destination and anchor into the operation input", () {
      final document = _document;
      final offer =
          dropCandidateIndex(
                _scope,
                [_page1],
                destinations: {
                  fixtureOperationId("MoveToOwner"): [_bookB],
                },
              ).offersFor([
                DropDestination.resource(_bookB, anchor: const Offset(3, 4)),
              ], document).single
              as OperationDropOffer;
      expect(offer.anchor, const Offset(3, 4));
      final input = seedDropInput(
        document,
        offer.operation,
        destination: offer.destination,
        anchor: offer.anchor,
      )!;
      expect(input.authoredField("destination")?.authoredString, _bookB.value);
      final anchor = input.authoredField("anchor")!.authoredRecord!;
      expect(
        [for (final field in anchor.fields) field.value],
        [skir.DataValue.wrapFloat(3), skir.DataValue.wrapFloat(4)],
      );
    });
  });

  group("regroup", () {
    test("offers a group only when a dragged value changes", () {
      final document = _document;
      final index = dropCandidateIndex(_scope, [_page1]);
      expect(
        index.offersFor([DropDestination.regroup(_chapter, "act1")], document),
        isEmpty,
      );
      expect(
        index.offersFor([
          DropDestination.regroup(_chapter, "act2"),
        ], document).single,
        DropOffer.regroup(field: _chapter, value: "act2"),
      );
    });

    test(
      "a dragged group keeps the paths below it and never enters itself",
      () {
        final document = _document;
        final drag = ResourceDrag(
          scope: _scope,
          primary: AuthoringResourceIdentifier.inScope(_scope, _page1),
          subjects: [_page1, _page2],
          group: DraggedGroup(field: _chapter, path: "act1"),
        );
        expect(document.regroupedValues(drag, _chapter, "act2"), {
          _page1: "act2.act1",
          _page2: "act2.act1.intro",
        });
        expect(document.regroupedValues(drag, _chapter, "act1"), isNull);
        expect(document.regroupedValues(drag, _chapter, "act1.intro"), isNull);
      },
    );
  });

  group("link fields", () {
    test("a collection takes every dragged resource", () {
      final document = _document;
      expect(
        dropCandidateIndex(_scope, [_tag1, _tag2]).offersFor([
          DropDestination.linkField(authoredFieldLocation(_bookA, ["tags"])),
        ], document),
        [
          DropOffer.link(location: authoredFieldLocation(_bookA, ["tags"])),
        ],
      );
    });

    test("a single value field rejects several dragged resources", () {
      final document = _document;
      final book = authoredFieldLocation(_page1, ["book"]);
      expect(
        dropCandidateIndex(_scope, [
          _bookB,
        ]).offersFor([DropDestination.linkField(book)], document),
        hasLength(1),
      );
      expect(
        dropCandidateIndex(_scope, [
          _bookA,
          _bookB,
        ]).offersFor([DropDestination.linkField(book)], document),
        isEmpty,
      );
    });

    test("an already linked resource is not linked again", () {
      final document = _document;
      expect(
        dropCandidateIndex(_scope, [_tag3]).offersFor([
          DropDestination.linkField(authoredFieldLocation(_bookA, ["tags"])),
        ], document),
        isEmpty,
      );
    });

    test(
      "a resource owned elsewhere falls through to the owner's operations",
      () {
        final document = _document;
        final offers =
            dropCandidateIndex(
              _scope,
              [_page1],
              destinations: {
                fixtureOperationId("MoveToOwner"): [_bookB],
              },
            ).offersFor([
              DropDestination.linkField(
                authoredFieldLocation(_bookB, ["pages"]),
              ),
              DropDestination.resource(_bookB),
            ], document);
        final offer = offers.single as OperationDropOffer;
        expect(offer.label, "Move to");
        expect(offer.destination, _bookB);
      },
    );

    test("a member dropped on a graph joins it centred on the drop point", () {
      final owned = _document;
      final taxonomyLink = owned.links.singleWhere(
        (link) => link.first == taxonomyId && link.second == _tag3,
      );
      final detached = AuthoringEdit.fromDocument(owned)
        ..disconnect(
          skir.LinkOccurrence(
            id: skir.LinkOccurrenceId(
              endpoint: owned.catalog.snapshot.relations
                  .singleWhere((item) => item.id == taxonomyLink.contract)
                  .first
                  .id,
              location: skir.ValueLocation(
                resource: taxonomyId,
                path: taxonomyLink.firstLocation!,
              ),
            ),
            source: taxonomyId,
            target: skir.LinkTarget(
              resource: _tag3,
              opposite: taxonomyLink.secondLocation,
            ),
          ),
        );
      final document = detached.toDocument();
      final tags = authoredFieldLocation(taxonomyId, ["tags"]);
      const anchor = Offset(20, 10);
      expect(document.canLinkAll(tags, [_tag3]), isTrue);

      final linked = (AuthoringEdit.fromDocument(
        document,
      )..linkDropped(tags, [_tag3], anchor: anchor)).toDocument();

      expect(linked.relations.parents[_tag3], [taxonomyId]);
      final rect = linked.resource(_tag3)!.graphRect(linked.catalog)!;
      // Cells are whole, so the centre lands within half a cell.
      expect(
        (rect.x + rect.width / 2 - anchor.dx).abs(),
        lessThanOrEqualTo(0.5),
      );
      expect(
        (rect.y + rect.height / 2 - anchor.dy).abs(),
        lessThanOrEqualTo(0.5),
      );
    });

    test("a link drop of several resources links every one of them", () {
      final books = AuthoringEdit.fromDocument(_document)
        ..linkDropped(authoredFieldLocation(_bookB, ["tags"]), [_tag1, _tag2]);

      expect(
        books.toDocument().linkedAt(authoredFieldLocation(_bookB, ["tags"])),
        {_tag1, _tag2},
      );
    });
  });
}

final _scope = AuthoringScope(
  organizationId: skir.recordId("organization:drop"),
  realmId: skir.recordId("realm:drop"),
);
final _bookA = skir.ResourceId(value: "book:a");
final _bookB = skir.ResourceId(value: "book:b");
final _page1 = skir.ResourceId(value: "page:one");
final _page2 = skir.ResourceId(value: "page:two");
final _tag1 = skir.ResourceId(value: "tag:one");
final _tag2 = skir.ResourceId(value: "tag:two");
final _tag3 = skir.ResourceId(value: "tag:three");
final _chapter = editorRootPath.field("chapter");

final _inputType = skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "drop-test", name: "Input"),
  revision: 1,
);

final _destination = skir.FieldOwner(
  definition: _inputType,
  name: "destination",
);
final _anchor = skir.FieldOwner(definition: _inputType, name: "anchor");
final _inputFields = [
  (_destination, skir.TypeTemplate.wrapScalar(skir.ScalarKind.text)),
  (
    _anchor,
    skir.TypeTemplate.createNullable(
      value: skir.TypeTemplate.createNamed(
        definition: placementAnchorTypeRef,
        arguments: const [],
      ),
    ),
  ),
];
final _dropOperations = [
  ("MoveToOwner", "Move to", skir.OperationGroup.organize, 10),
  ("LinkWith", "Link with", skir.OperationGroup.organize, 20),
  ("Annotate", "Annotate", skir.OperationGroup.edit, 50),
];

/// Books A and B; A tags tag three and owns two pages in chapter act1. The
/// catalog declares three drop operations with one destination input.
final _document = realmDocument(
  catalog: CheckedEditorCatalog(
    (libraryCatalog().snapshot.toMutable()
          ..types = [
            ...libraryCatalog().snapshot.types,
            publishedType(
              _inputType,
              representation: skir.RepresentationTemplate.createRecord(
                form: skir.RecordForm.concrete,
                fields: [
                  for (final (owner, type) in _inputFields)
                    skir.FieldDeclaration(
                      owner: owner,
                      type: type,
                      overrides: const [],
                      hasConstructorDefault: false,
                    ),
                ],
              ),
              fields: [
                for (final (owner, type) in _inputFields)
                  skir.EffectiveFieldTemplate(
                    key: owner.name,
                    owner: owner,
                    type: type,
                    rules: const [],
                  ),
              ],
            ),
          ]
          ..capabilities = [
            ...libraryCatalog().snapshot.capabilities,
            for (final (name, _, _, _) in _dropOperations)
              skir.CapabilityDefinition.createAuthoring(
                capabilityId: skir.CapabilityId(value: "drop-test:$name"),
                targets: _targets,
                input: skir.OperationInputDefinition(
                  type: skir.TypeUse.createNamed(
                    definition: _inputType,
                    arguments: const [],
                  ),
                  presentation: null,
                ),
              ),
          ]
          ..resourceOperations = [
            for (final (name, label, group, order) in _dropOperations)
              skir.ResourceOperationDefinition(
                id: fixtureOperationId(name),
                targets: _targets,
                capability: skir.CapabilityId(value: "drop-test:$name"),
                drop: skir.OperationDrop(
                  input: editorRootPath.field("destination"),
                  hint: label,
                ),
                presentation: skir.OperationPresentation(
                  label: label,
                  description: "",
                  icon: "",
                  group: group,
                  order: order,
                  tone: skir.HeaderActionTone.neutral,
                  confirmation: null,
                  inspector: skir.OperationInspector.hidden,
                  shortcut: null,
                  emphasis: skir.OperationEmphasis.flat,
                ),
              ),
          ])
        .toFrozen(),
  ),
  books: [
    Book(
      bookId: _bookA,
      title: "A",
      icon: "mdi:book",
      color: Colors.blue,
      tagIds: [_tag3],
    ),
    Book(bookId: _bookB, title: "B", icon: "mdi:book", color: Colors.green),
  ],
  tags: [
    for (final tag in [_tag1, _tag2, _tag3])
      Tag(tagId: tag, name: tag.value, color: Colors.red),
  ],
  pages: [
    Page(pageId: _page1, name: "One", bookId: _bookA, chapter: "act1"),
    Page(pageId: _page2, name: "Two", bookId: _bookA, chapter: "act1.intro"),
  ],
);

final _targets = skir.OperationTargets(
  subject: skir.ResourceTarget.anyResource,
  cardinality: skir.OperationCardinality.selection,
);
