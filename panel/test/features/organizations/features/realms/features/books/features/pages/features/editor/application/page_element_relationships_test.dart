import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("remote graph placement", () {
    test("maps incoming majority to every graph direction", () {
      final cases = [
        (GraphDirection.leftToRight, (GraphGridRect rect) => rect.right <= 10),
        (GraphDirection.rightToLeft, (GraphGridRect rect) => rect.x >= 14),
        (GraphDirection.topToBottom, (GraphGridRect rect) => rect.bottom <= 10),
        (GraphDirection.bottomToTop, (GraphGridRect rect) => rect.y >= 12),
      ];

      for (final (direction, isAllowed) in cases) {
        final placement = RemoteGraphPlacementSession().place(
          elements: _pageWithRemote(incoming: 3, outgoing: 1),
          direction: direction,
          emptyGraphAnchor: Offset.zero,
        )["remote"]!;

        expect(isAllowed(placement), isTrue, reason: direction.name);
      }
    });

    test("ties choose the outgoing side", () {
      final placement = RemoteGraphPlacementSession().place(
        elements: _pageWithRemote(incoming: 2, outgoing: 2),
        direction: GraphDirection.leftToRight,
        emptyGraphAnchor: Offset.zero,
      )["remote"]!;

      expect(placement.x, greaterThanOrEqualTo(14));
    });

    test("retains side and position when occurrence counts change", () {
      final session = RemoteGraphPlacementSession();
      final initial = session.place(
        elements: _pageWithRemote(incoming: 3, outgoing: 1),
        direction: GraphDirection.leftToRight,
        emptyGraphAnchor: Offset.zero,
      )["remote"]!;
      final refreshed = session.place(
        elements: _pageWithRemote(incoming: 1, outgoing: 4),
        direction: GraphDirection.leftToRight,
        emptyGraphAnchor: Offset.zero,
      )["remote"]!;

      expect(refreshed, initial);
      expect(refreshed.right, lessThanOrEqualTo(10));
    });

    test("reserves each remote rectangle before placing the next", () {
      final elements = [
        _local(
          inward: const [],
          outward: [_link("local:.a", "a", ".a"), _link("local:.b", "b", ".b")],
        ),
        _remote("a"),
        _remote("b"),
      ];

      final placements = RemoteGraphPlacementSession().place(
        elements: elements,
        direction: GraphDirection.leftToRight,
        emptyGraphAnchor: Offset.zero,
      );

      expect(placements["a"]!.overlaps(placements["b"]!, gap: 1), isFalse);
    });

    test("a new earlier identifier does not move a retained node", () {
      final session = RemoteGraphPlacementSession();
      final initial = session.place(
        elements: [
          _local(inward: const [], outward: [_link("local:.z", "z", ".z")]),
          _remote("z"),
        ],
        direction: GraphDirection.leftToRight,
        emptyGraphAnchor: Offset.zero,
      )["z"]!;

      final refreshed = session.place(
        elements: [
          _local(
            inward: const [],
            outward: [
              _link("local:.a", "a", ".a"),
              _link("local:.z", "z", ".z"),
            ],
          ),
          _remote("a"),
          _remote("z"),
        ],
        direction: GraphDirection.leftToRight,
        emptyGraphAnchor: Offset.zero,
      );

      expect(refreshed["z"], initial);
      expect(refreshed["a"]!.overlaps(initial, gap: 1), isFalse);
    });

    test(
      "unavailable remote resources keep direction and avoid collisions",
      () {
        final placements = RemoteGraphPlacementSession().place(
          elements: [
            _local(
              inward: [_link("incoming:.source", "incoming", ".source")],
              outward: [
                _link("local:.first", "first", ".first"),
                _link("local:.second", "second", ".second"),
              ],
            ),
            _unavailable("incoming"),
            _unavailable("first"),
            _unavailable("second"),
          ],
          direction: GraphDirection.leftToRight,
          emptyGraphAnchor: Offset.zero,
        );

        expect(placements["incoming"]!.right, lessThanOrEqualTo(10));
        expect(placements["first"]!.x, greaterThanOrEqualTo(14));
        expect(placements["second"]!.x, greaterThanOrEqualTo(14));
        expect(
          placements["first"]!.overlaps(placements["second"]!, gap: 1),
          isFalse,
        );
        expect(placements.values.toSet(), hasLength(3));
      },
    );
  });

  test("groups duplicate endpoints while preserving every occurrence", () {
    final relationships = [
      _local(
        inward: const [],
        outward: const [
          ElementLink(
            linkId: "local:.fallback",
            otherId: "remote",
            path: ".fallback",
          ),
          ElementLink(
            linkId: "local:.success",
            otherId: "remote",
            path: ".success",
          ),
        ],
      ),
      _remote("remote"),
    ].relationshipsFor("local");

    expect(relationships.outgoing, hasLength(1));
    expect(relationships.outgoing.single.resourceId, "remote");
    expect(relationships.outgoing.single.usages.map((usage) => usage.slot), [
      ".fallback",
      ".success",
    ]);
  });
}

List<PageElement> _pageWithRemote({
  required int incoming,
  required int outgoing,
}) => [
  _local(
    inward: [
      for (var index = 0; index < incoming; index++)
        _link("remote:.in$index", "remote", ".in$index"),
    ],
    outward: [
      for (var index = 0; index < outgoing; index++)
        _link("local:.out$index", "remote", ".out$index"),
    ],
  ),
  _remote("remote"),
];

PageElement _local({
  required List<ElementLink> inward,
  required List<ElementLink> outward,
}) => PageElement.entry(
  entry: PageEntry.definition(
    definition: EntryDefinition(
      id: "local",
      elementDefinition: _elementDefinition,
      placement: const EntryPlacement(x: 10, y: 10, width: 4, height: 2),
      data: RecordValue({"name": const StringValue("Local")}),
      inwardEdges: inward,
      outwardEdges: outward,
    ),
  ),
);

PageElement _remote(String id) => PageElement.entry(
  entry: PageEntry.reference(
    id: id,
    name: id,
    subject: _subject(id, "remote_page"),
    elementDefinition: _elementDefinition,
    pageId: "remote_page",
  ),
);

PageElement _unavailable(String id) => PageElement.entry(
  entry: PageEntry.unavailableReference(id: id, name: "Unavailable $id"),
);

TypedPresentationSubject _subject(String id, String owner) => (
  content: TypedValueEnvelope(
    rootType: referenceResourceTypes.element,
    rootValue: const StringValue("content"),
  ),
  descriptor: TypedValueEnvelope(
    rootType: referenceResourceTypes.element,
    rootValue: const StringValue("descriptor"),
  ),
  identityEnvelope: TypedValueEnvelope(
    rootType: referenceResourceTypes.element,
    rootValue: const StringValue("identity"),
  ),
  identity: (
    id: skir.ResourceId(value: id),
    owner: skir.ResourceId(value: owner),
  ),
);

ElementLink _link(String id, String otherId, String path) =>
    ElementLink(linkId: id, otherId: otherId, path: path);

final _elementDefinition = ElementDefinition(
  rootType: ResolvedTypeRef(
    id: DeclaredTypeId("0123456789abcdef0123456789abcdef"),
    revision: 1,
  ),
  name: "Example",
  description: "Example entry",
  color: Colors.blue,
  icon: const IconValue.iconify("fa-solid:star"),
);
