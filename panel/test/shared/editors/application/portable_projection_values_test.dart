import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("portable projections use structural equality", () {
    final first = PortableCollectionProjection(definition: null, rows: []);
    final second = PortableCollectionProjection(definition: null, rows: []);

    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  test("portable projection collections are read only", () {
    final collection = PortableCollectionProjection(definition: null, rows: []);
    final resource = skir.ResourceId(value: "resource:test");
    final page = PortableResourcesProjection(
      members: const [],
      edges: const [],
      timeline: {resource: []},
    );

    expect(collection.rows.clear, throwsUnsupportedError);
    expect(page.members.clear, throwsUnsupportedError);
    expect(page.timeline[resource]!.clear, throwsUnsupportedError);
  });

  test("portable projections detach from supplied collections", () {
    final resource = skir.ResourceId(value: "resource:test");
    final rows = <PortableCollectionRowProjection>[];
    final entries = <PortableResourceMember>[];
    final edges = <PortableResourceEdge>[];
    final cues = <PortableTimelineCueProjection>[];
    final collection = PortableCollectionProjection(
      definition: null,
      rows: rows,
    );
    final page = PortableResourcesProjection(
      members: entries,
      edges: edges,
      timeline: {resource: cues},
    );

    rows.add(
      PortableCollectionRowProjection(
        resource: resource,
        configuration: skir.TypeSelection.unknown,
        label: "Row",
        row: skir.DataValue.unfilled,
        key: skir.DataValue.unfilled,
        canonicalKey: "row",
        selectable: true,
      ),
    );
    entries.add(
      PortableResourceMember(
        resource: resource,
        occurrence: skir.LinkOccurrence.defaultInstance,
        link: skir.DataValue.unfilled,
        appearance: ResourceAppearance(
          label: "Entry",
          accent: const Color(0xff607d8b),
          icon: skir.Icon.wrapIconify("material-symbols:category"),
        ),
        resourceProjection: PortableResourceProjection(
          resource: resource,
          configuration: skir.TypeSelection.unknown,
          label: "Entry",
          value: skir.DataValue.unfilled,
        ),
      ),
    );
    edges.add(
      PortableResourceEdge(id: "edge:test", source: resource, target: resource),
    );
    cues.add(
      PortableTimelineCueProjection(
        resource: resource,
        label: "Cue",
        placement: const PortableTimelinePlacement.keyframe(1),
        children: const [],
      ),
    );

    expect(collection.rows, isEmpty);
    expect(page.members, isEmpty);
    expect(page.edges, isEmpty);
    expect(page.timeline[resource], isEmpty);
  });
}
