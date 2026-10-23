import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../support/test_utils.dart";

void main() {
  testWidgets(
    "a foreign resource dropped onto a graph canvas is linked and placed at "
    "the pointer",
    (tester) async {
      final container = await _pump(tester);
      final canvas = find.descendant(
        of: find.byType(Graph),
        matching: find.byType(ResourceDropHighlight),
      );
      expect(canvas, findsOneWidget);
      final pointer = tester.getCenter(canvas) + const Offset(200, 150);
      final gesture = await tester.startGesture(
        tester.getCenter(find.text("Drag tag")),
      );
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump();
      await gesture.moveTo(pointer);
      await tester.pumpAndSettle();
      expect(find.text("Link here"), findsOneWidget);
      final surface = tester.renderObject<RenderBox>(find.byType(GraphSurface));
      final anchor = surface.globalToLocal(pointer) / 50;
      await gesture.up();
      await tester.pumpAndSettle();

      final scope = container.read(selectedAuthoringScopeProvider)!;
      final document = container.read(realmEditingProvider(scope)).document;
      expect(document.relations.parents[_detached], [fixtureTaxonomyId]);
      final rect = document.resource(_detached)!.graphRect(document.catalog)!;
      expect((rect.x - (anchor.dx - 2).round()).abs(), lessThanOrEqualTo(1));
      expect((rect.y - (anchor.dy - 0.5).round()).abs(), lessThanOrEqualTo(1));
    },
  );
}

final _tags = [
  skir.ResourceId(value: "tag:a"),
  skir.ResourceId(value: "tag:b"),
];
final _detached = skir.ResourceId(value: "tag:detached");

/// Tags a and b in the taxonomy graph; the detached tag has no owner.
AuthoringDocument _document() {
  final owned = fixtureAuthoringDocument(
    realm: true,
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
    (link) => link.first == fixtureTaxonomyId && link.second == _detached,
  );
  return (AuthoringEdit.fromDocument(owned)..disconnect(
        skir.LinkOccurrence(
          id: skir.LinkOccurrenceId(
            endpoint: owned.catalog.snapshot.relations
                .singleWhere((item) => item.id == link.contract)
                .first
                .id,
            location: skir.ValueLocation(
              resource: fixtureTaxonomyId,
              path: link.firstLocation!,
            ),
          ),
          source: fixtureTaxonomyId,
          target: skir.LinkTarget(
            resource: _detached,
            opposite: link.secondLocation,
          ),
        ),
      ))
      .toDocument();
}

Future<ProviderContainer> _pump(WidgetTester tester) async {
  await tester.pumpTestApp(
    overrides: [
      realmInteractionProvider.overrideWithValue(
        const RealmInteractionState(
          connectionState: RealmConnectionState.online,
        ),
      ),
      ...authoringFixtureOverrides(document: _document()),
    ],
    child: Scaffold(
      body: SizedBox(
        width: 1000,
        height: 700,
        child: HookConsumer(
          builder: (context, ref, _) {
            final scope = ref.watch(selectedAuthoringScopeProvider)!;
            final workspace = ref.watch(realmEditingProvider(scope));
            useListenable(workspace);
            final binding = useMemoized(
              () => workspace.attach(
                fixtureTaxonomyId,
                policy: EditorCommitPolicy.applyResource,
              ),
              [workspace],
            );
            useEffect(() => binding.detach, [binding]);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 150,
                  child: ResourceDragSource(
                    drag: ResourceDrag(
                      scope: scope,
                      primary: AuthoringResourceIdentifier.inScope(
                        scope,
                        _detached,
                      ),
                      subjects: [_detached],
                    ),
                    enabled: true,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text("Drag tag"),
                    ),
                  ),
                ),
                Expanded(
                  child: AuthoredResourceEditor(
                    resource: fixtureTaxonomyId,
                    document: workspace.document,
                    edit: binding,
                    role: skir.PresentationRole.workspace,
                    budget: skir.EvaluationBudget(
                      maxSteps: 10000,
                      maxCollectionItems: 1000,
                    ),
                    fillAvailableSpace: true,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.container();
}
