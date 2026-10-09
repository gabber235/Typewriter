import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/features/books/features/pages/presentation/route.stories.dart";

void main() {
  testWidgets("graph workspace selects an entry and commits its placement", (
    tester,
  ) async {
    final transport = ScriptedAuthoringTransport(
      AsyncData(pageWorkspaceStoryDocument()),
    );
    final workspace = AuthoringWorkspace(
      transport: transport,
      initial: transport.observation.requireValue,
    );
    addTearDown(workspace.dispose);
    addTearDown(transport.dispose);
    skir.ResourceId? selected;
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      FakeApp(
        child: PageWorkspaceStory(
          timeline: false,
          workspace: workspace,
          onResourceSelected: (resource) => selected = resource,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final graph = tester.widget<Graph>(find.byType(Graph));
    graph.onElementsMoved!([
      GraphMoveCommitPayload(
        id: const GraphIdentifier("entry:reward"),
        x: 9,
        y: 6,
      ),
    ]);
    await tester.pump();

    final reward = workspace.document.resource(
      skir.ResourceId(value: "entry:reward"),
    )!;
    expect(
      reward.authoredField("placement")!.authoredField("x")!.authoredInteger,
      BigInt.from(9),
    );
    expect(
      reward.authoredField("placement")!.authoredField("y")!.authoredInteger,
      BigInt.from(6),
    );

    await tester.tap(find.text("Reward").first);
    await tester.pumpAndSettle();
    expect(selected?.value, "entry:reward");
    expect(find.text("Reward"), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pump(AuthoringWorkspace.debounce);
    await tester.pumpAndSettle();
  });

  testWidgets("timeline workspace commits cue frames through shared work", (
    tester,
  ) async {
    final transport = ScriptedAuthoringTransport(
      AsyncData(pageWorkspaceStoryDocument()),
    );
    final workspace = AuthoringWorkspace(
      transport: transport,
      initial: transport.observation.requireValue,
    );
    addTearDown(workspace.dispose);
    addTearDown(transport.dispose);
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      FakeApp(child: PageWorkspaceStory(timeline: true, workspace: workspace)),
    );
    await tester.pumpAndSettle();

    final timeline = tester.widget<Timeline>(find.byType(Timeline));
    await timeline.onElementsCommited!([
      TimelineCommitPayload(
        id: const TimelineIdentifier("cue:dialogue"),
        startFrame: 24,
        endFrame: 96,
      ),
    ]);
    await tester.pump();

    final cue = workspace.document.resource(
      skir.ResourceId(value: "cue:dialogue"),
    )!;
    expect(
      cue
          .authoredField("placement")!
          .authoredField("startFrame")!
          .authoredInteger,
      BigInt.from(24),
    );
    expect(
      cue
          .authoredField("placement")!
          .authoredField("endFrame")!
          .authoredInteger,
      BigInt.from(96),
    );
    expect(tester.takeException(), isNull);
    await tester.pump(AuthoringWorkspace.debounce);
    await tester.pumpAndSettle();
  });
}
