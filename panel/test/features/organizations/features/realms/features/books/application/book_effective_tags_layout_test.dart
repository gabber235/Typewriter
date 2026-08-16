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

      await tester.tap(find.text("Inheritance path"));
      await tester.pumpAndSettle();

      expect(find.text("Inheritance path"), findsOneWidget);
      expect(find.text(directTag.name), findsNWidgets(2));
      expect(find.text(inheritedTag.name), findsNWidgets(2));
      expect(find.text("›"), findsOneWidget);
      expect(find.byType(Chip), findsNWidgets(4));
    },
  );

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
