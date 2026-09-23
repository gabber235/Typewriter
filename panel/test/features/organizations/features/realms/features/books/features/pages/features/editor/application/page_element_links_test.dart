import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test(
    "projected links follow current reference values in both directions",
    () {
      final source = _entry(
        "source",
        RecordValue({
          "name": const StringValue("Source"),
          "targets": ListValue([
            ReferenceValue(skir.ResourceId(value: "target")),
          ]),
        }),
        outward: const [
          ElementLink(
            linkId: "source:.targets[0]",
            otherId: "old",
            path: ".targets[0]",
          ),
          ElementLink(
            linkId: "source_child",
            otherId: "child",
            path: "children",
          ),
        ],
      );
      final target = _entry(
        "target",
        RecordValue({"name": const StringValue("Target")}),
      );

      final projected = [source, target].projectLinks();
      final projectedSource = _definition(projected.first);
      final projectedTarget = _definition(projected.last);

      expect(projectedSource.outwardEdges, [
        const ElementLink(
          linkId: "source_child",
          otherId: "child",
          path: "children",
        ),
        ElementLink(
          linkId: "source:.targets[0]",
          otherId: "target",
          path: ".targets[0]",
          sourcePath: DataPath.root.field("targets").index(0),
        ),
      ]);
      expect(projectedTarget.inwardEdges, [
        ElementLink(
          linkId: "source:.targets[0]",
          otherId: "source",
          path: ".targets[0]",
          sourcePath: DataPath.root.field("targets").index(0),
        ),
      ]);

      final withoutReference = [
        source.updateFieldValue(
          DataPath.root.field("targets"),
          const ListValue([]),
        ),
        target,
      ].projectLinks();
      expect(_definition(withoutReference.first).outwardEdges, const [
        ElementLink(linkId: "source_child", otherId: "child", path: "children"),
      ]);
      expect(_definition(withoutReference.last).inwardEdges, isEmpty);
    },
  );

  test("preserves distinct slots between identical endpoints", () {
    final projected = [
      _entry(
        "source",
        RecordValue({
          "fallback": ReferenceValue(skir.ResourceId(value: "target")),
          "success": ReferenceValue(skir.ResourceId(value: "target")),
        }),
      ),
      _entry("target", RecordValue({"name": const StringValue("Target")})),
    ].projectLinks();

    expect(
      _definition(projected.first).outwardEdges.map((link) => link.linkId),
      ["source:.fallback", "source:.success"],
    );
    expect(_definition(projected.last).inwardEdges.map((link) => link.linkId), [
      "source:.fallback",
      "source:.success",
    ]);
  });
}

PageElement _entry(
  String id,
  RecordValue data, {
  List<ElementLink> inward = const [],
  List<ElementLink> outward = const [],
}) => PageElement.entry(
  entry: PageEntry.definition(
    definition: EntryDefinition(
      id: id,
      elementDefinition: _elementDefinition,
      placement: const EntryPlacement(x: 0, y: 0, width: 4, height: 1),
      data: data,
      inwardEdges: inward,
      outwardEdges: outward,
    ),
  ),
);

EntryDefinition _definition(PageElement element) =>
    ((element as PageElementEntry).entry as DefinitionPageEntry).definition;

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
