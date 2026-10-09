import "package:flutter_test/flutter_test.dart" hide Tags;
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../../../support/test_utils.dart";

void main() {
  testWidgets("points parent tag edges into their child", (tester) async {
    final parentId = skir.ResourceId(value: "parent");
    final childId = skir.ResourceId(value: "child");
    final tags = [
      _tag(TagIdentifier(parentId), "Parent", x: 0),
      _tag(TagIdentifier(childId), "Child", x: 0, y: 3, parentIds: [parentId]),
    ];

    await tester.pumpTestApp(
      overrides: authoringFixtureOverrides(tags: tags),
      child: const SizedBox(width: 800, height: 600, child: TagGraph()),
    );

    final edge = tester
        .renderObject<RenderGraphSurface>(find.byType(GraphSurface))
        .visibleEdges
        .single;
    expect(edge.edge.source, GraphIdentifier(parentId.id));
    expect(edge.edge.target, GraphIdentifier(childId.id));
    expect(edge.edge.sourceSide, EdgeSide.bottom);
    expect(edge.edge.targetSide, EdgeSide.top);
  });

  testWidgets("the graph shows a shared manual rename before Apply", (
    tester,
  ) async {
    final id = skir.ResourceId(value: "tag:shared");
    final document = fixtureAuthoringDocument(
      tags: [_tag(TagIdentifier(id), "Original", x: 0)],
    );
    final transport = ScriptedAuthoringTransport(AsyncData(document));
    addTearDown(transport.dispose);
    await tester.pumpTestApp(
      overrides: authoringFixtureOverrides(transport: transport),
      child: const SizedBox(width: 800, height: 600, child: TagGraph()),
    );
    final container = tester.container();
    final workspace = container.read(
      authoringWorkspaceProvider(
        container.read(selectedAuthoringScopeProvider)!,
      ),
    );
    final binding = workspace.attach(
      id,
      policy: EditorCommitPolicy.applyResource,
    );
    addTearDown(binding.detach);
    binding.edit(
      label: "Rename tag",
      apply: (edit) => edit.set(
        authoredFieldLocation(id, ["name"]),
        skir.DataValue.wrapStringValue("Shared name"),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("Shared name"), findsOneWidget);
    expect(
      container.read(workingTagsProvider).requireValue.single.name,
      "Shared name",
    );
    expect(transport.requests, isEmpty);
    expect(
      transport.observation.requireValue
          .resource(id)!
          .authoredField("name")!
          .authoredString,
      "Original",
    );
    binding.discard();
    await tester.pumpAndSettle();
    expect(find.text("Original"), findsOneWidget);
  });

  testWidgets(
    "selected tag movement publishes together before acknowledgement",
    (tester) async {
      final firstId = skir.ResourceId(value: "first");
      final secondId = skir.ResourceId(value: "second");
      final tags = [
        _tag(TagIdentifier(firstId), "First Tag", x: 0),
        _tag(TagIdentifier(secondId), "Second Tag", x: 3),
      ];
      final transport = ScriptedAuthoringTransport(
        AsyncData(fixtureAuthoringDocument(tags: tags)),
      );
      addTearDown(transport.dispose);

      await tester.pumpTestApp(
        settle: false,
        overrides: [...authoringFixtureOverrides(transport: transport)],
        child: const SizedBox(width: 800, height: 600, child: TagGraph()),
      );
      await tester.pumpAndSettle();

      final selectors = {
        for (final selector in tester.widgetList<Selector>(
          find.byType(Selector),
        ))
          selector.selectableId.id: selector,
      };
      tester.container().read(selectionProvider.notifier).selectAll([
        TagIdentifier(firstId),
        TagIdentifier(secondId),
      ]);
      selectors[firstId.id]!.focusNode.requestFocus();
      await tester.pump();
      Actions.invoke(
        selectors[firstId.id]!.focusNode.context!,
        const GraphMoveIntent(direction: TraversalDirection.right),
      );
      await tester.pumpUntil(() {
        expect(transport.requests, hasLength(1));
      });

      expect(transport.requests.single.edit.intents, hasLength(2));
      expect(
        transport.requests.single.edit.intents
            .whereType<skir.EditIntent_setValueWrapper>()
            .map((intent) => intent.value.at.resource)
            .toSet(),
        {firstId, secondId},
      );
      expect(
        transport.observation.requireValue
            .resource(firstId)!
            .authoredField("placement")!
            .authoredRecord!
            .fields
            .first
            .value
            .authoredInteger,
        BigInt.zero,
      );
      await tester.pumpAndSettle();

      final moved = {
        for (final tag
            in tester.container().read(workingTagsProvider).requireValue)
          tag.tagId: tag.placement.x,
      };
      expect(moved[firstId], 1);
      expect(moved[secondId], 4);
    },
  );
}

Tag _tag(
  TagIdentifier identifier,
  String name, {
  required int x,
  int y = 0,
  List<skir.ResourceId> parentIds = const [],
}) {
  return Tag(
    tagId: identifier.tagId,
    name: name,
    color: Colors.blue,
    parentIds: parentIds,
    placement: GraphPlacement(x: x, y: y, width: 2, height: 1),
  );
}
