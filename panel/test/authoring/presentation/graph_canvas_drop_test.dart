import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("a foreign resource dropped onto a graph canvas is linked and "
      "placed at the pointer", (tester) async {
    // Tags a and b in the taxonomy graph; the detached tag has no owner.
    final owned = realmDocument(
      tags: [
        for (final (index, tag) in [..._tags, _detached].indexed)
          Tag(
            tagId: tag,
            name: tag.value,
            color: Colors.red,
            placement: GraphPlacement(x: index * 6, y: 0, width: 4, height: 1),
          ),
      ],
    );
    final link = owned.links.singleWhere(
      (link) => link.first == taxonomyId && link.second == _detached,
    );
    final seeded = owned.changedRemotely(
      (edit) => edit.disconnect(
        skir.LinkOccurrence(
          id: skir.LinkOccurrenceId(
            endpoint: owned.catalog.snapshot.relations
                .singleWhere((item) => item.id == link.contract)
                .first
                .id,
            location: skir.ValueLocation(
              resource: taxonomyId,
              path: link.firstLocation!,
            ),
          ),
          source: taxonomyId,
          target: skir.LinkTarget(
            resource: _detached,
            opposite: link.secondLocation,
          ),
        ),
      ),
    );
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realmServing(seeded),
    ]);
    await panel.openSurface(taxonomyId);
    final source = await panel.showDraggable(_detached, "Drag tag");
    final canvas = tester.getRect(find.byType(GraphSurface));
    final pointer = canvas.center + const Offset(200, 150);

    final gesture = await tester.startGesture(source.center);
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
    await gesture.moveTo(pointer);
    await tester.pumpAndSettle();
    expect(find.text("Link here"), findsOneWidget);
    final surface = tester.renderObject<RenderBox>(find.byType(GraphSurface));
    final anchor = surface.globalToLocal(pointer) / 50;
    await gesture.up();
    await panel.settle();

    final document = panel.working;
    expect(document.relations.parents[_detached], [taxonomyId]);
    final rect = document.resource(_detached)!.graphRect(document.catalog)!;
    // The four cell wide node is centered on the pointer's cell.
    expect(rect.x, closeTo(anchor.dx - rect.width / 2, 1));
    expect(rect.y, closeTo(anchor.dy - rect.height / 2, 1));
  });
}

final _tags = [
  skir.ResourceId(value: "tag:a"),
  skir.ResourceId(value: "tag:b"),
];
final _detached = skir.ResourceId(value: "tag:detached");
