import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart" hide Tags;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../../../support/test_utils.dart";

void main() {
  testWidgets(
    "effective Tags fit a narrow inspector and remain keyboard usable",
    (tester) async {
      final directTag = _tag(
        "tag:direct",
        name: "A moderately long direct Tag name",
        parents: ["tag:inherited"],
      );
      final inheritedTag = _tag(
        "tag:inherited",
        name: "A moderately long inherited Tag name",
      );

      await tester.pumpTestApp(
        child: Center(
          child: SizedBox(
            width: 400,
            child: _renderer([directTag, inheritedTag], [directTag.tagId.id]),
          ),
        ),
        settle: false,
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text(directTag.name), findsOneWidget);
      expect(find.text(inheritedTag.name), findsOneWidget);
      expect(find.byType(Chip), findsNWidgets(2));
      for (final chip in tester.widgetList<Chip>(find.byType(Chip))) {
        expect(chip.side, isA<BorderSide>());
        expect(chip.side!.color.toARGB32(), Colors.blue.toARGB32());
        final box = tester.renderObject<RenderBox>(find.byWidget(chip));
        expect(box.size.width, lessThanOrEqualTo(400));
      }
      expect(find.text("Inheritance path"), findsNothing);
      expect(find.text(directTag.name), findsOneWidget);
      expect(find.text(inheritedTag.name), findsOneWidget);
    },
  );

  testWidgets("branching Tags use a collapsed bordered section", (
    tester,
  ) async {
    final directTag = _tag(
      "tag:direct",
      name: "Direct Tag",
      parents: ["tag:first", "tag:second"],
    );
    final first = _tag("tag:first", name: "First parent");
    final second = _tag("tag:second", name: "Second parent");

    await tester.pumpTestApp(
      child: Center(
        child: SizedBox(
          width: 400,
          child: _renderer([directTag, first, second], [directTag.tagId.id]),
        ),
      ),
      settle: false,
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text("Inheritance path"), findsNothing);
    expect(find.text(directTag.name), findsOneWidget);
    expect(find.text(first.name), findsNothing);
    expect(find.text(first.name, skipOffstage: false), findsOneWidget);
    expect(find.text(second.name, skipOffstage: false), findsOneWidget);

    await tester.tap(find.text(directTag.name));
    await tester.pumpAndSettle();

    expect(find.text(first.name), findsOneWidget);
    expect(find.text(second.name), findsOneWidget);
  });

  testWidgets("shared branching ancestors repeat with independent expansion", (
    tester,
  ) async {
    final firstRoot = _tag(
      "tag:firstRoot",
      name: "First root",
      parents: ["tag:shared"],
    );
    final secondRoot = _tag(
      "tag:secondRoot",
      name: "Second root",
      parents: ["tag:shared"],
    );
    final shared = _tag(
      "tag:shared",
      name: "Shared parent",
      parents: ["tag:firstLeaf", "tag:secondLeaf"],
    );
    final firstLeaf = _tag("tag:firstLeaf", name: "First leaf");
    final secondLeaf = _tag("tag:secondLeaf", name: "Second leaf");
    late StateSetter rebuild;
    var revision = firstRoot.revision;

    await tester.pumpTestApp(
      child: StatefulBuilder(
        builder: (context, setState) {
          rebuild = setState;
          return Center(
            child: SizedBox(
              width: 400,
              child: _renderer(
                [
                  firstRoot.copyWith(revision: revision),
                  secondRoot,
                  shared,
                  firstLeaf,
                  secondLeaf,
                ],
                [firstRoot.tagId.id, secondRoot.tagId.id],
              ),
            ),
          );
        },
      ),
      settle: false,
    );
    await tester.pump();

    expect(find.text(shared.name), findsNWidgets(2));
    expect(find.text(firstLeaf.name), findsNothing);
    expect(find.text(firstLeaf.name, skipOffstage: false), findsNWidgets(2));

    await tester.tap(find.text(shared.name).first);
    await tester.pumpAndSettle();

    expect(find.text(firstLeaf.name), findsOneWidget);
    expect(find.text(secondLeaf.name), findsOneWidget);
    expect(find.text(firstLeaf.name, skipOffstage: false), findsNWidgets(2));

    rebuild(() => revision++);
    await tester.pump();

    expect(find.text(firstLeaf.name), findsOneWidget);
    expect(find.text(secondLeaf.name), findsOneWidget);
  });

  testWidgets("hides Effective Tags when the Book has no direct Tags", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: Center(
        child: SizedBox(width: 400, child: _renderer(const [], const [])),
      ),
      settle: false,
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text("Effective Tags"), findsNothing);
    expect(find.byType(Chip), findsNothing);
  });
}

Tag _tag(String id, {required String name, List<String> parents = const []}) =>
    Tag(
      tagId: recordId(id),
      revision: 1,
      name: name,
      color: Colors.blue,
      parentIds: parents.map(recordId).toList(),
      placement: const Placement(x: 0, y: 0, width: 4, height: 1),
    );

EditorProtocolRenderer _renderer(List<Tag> tags, List<String> rootTagIds) {
  const rootBinding = BindingReference(bindingId: BindingId(0));
  final rootType = ResolvedTypeRef(
    id: const QualifiedTypeId(namespace: "test", name: "bookTags"),
    revision: 1,
  );
  return EditorProtocolRenderer(
    envelope: TypedValueEnvelope(
      rootType: rootType,
      rootValue: ListValue(rootTagIds.map(StringValue.new).toList()),
    ),
    typeCatalog: TypeCatalog([
      TypeDefinition(
        id: rootType,
        kind: NominalTypeKind.concrete,
        representation: ListType(element: tagReferenceType),
      ),
    ]),
    collections: [tagPresentationCollection(tags)],
    presentation: effectiveTagGraph(
      id: "book.effectiveTags",
      title: "Effective Tags",
      roots: rootBinding,
    ),
  );
}
