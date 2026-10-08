import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/features/books/features/pages/presentation/route.stories.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/presentation/authored_resource_editor.stories.dart";

void main() {
  testWidgets("resource inspector edits the canonical authored draft", (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(Builder(builder: authoredResourceEditorUseCase));
    await tester.pumpAndSettle();

    final title = find.byType(TextFormField).first;
    expect(title, findsOneWidget);
    await tester.enterText(title, "Updated objective");
    await tester.pumpAndSettle();

    expect(find.text("Updated objective"), findsOneWidget);
    expect(find.byType(AuthoredResourceEditor), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("new draft keeps unfinished values editable", (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(Builder(builder: authoredNewDraftUseCase));
    await tester.pumpAndSettle();

    final title = find.byType(TextFormField).first;
    expect(tester.widget<TextFormField>(title).controller?.text, isEmpty);
    await tester.enterText(title, "New objective");
    await tester.pumpAndSettle();

    expect(find.text("New objective"), findsOneWidget);
    expect(find.byType(AuthoredResourceEditor), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("graph selection opens the selected resource inspector", (
    tester,
  ) async {
    skir.ResourceId? selected;
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      FakeApp(
        child: PageWorkspaceStory(
          timeline: false,
          onResourceSelected: (resource) => selected = resource,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text("Reward").first);
    await tester.pump(const Duration(milliseconds: 300));

    expect(selected?.value, "entry:reward");
    expect(find.byType(AuthoredResourceEditor), findsOneWidget);
    expect(find.text("Reward"), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets("timeline selection opens the selected cue inspector", (
    tester,
  ) async {
    skir.ResourceId? selected;
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      FakeApp(
        child: PageWorkspaceStory(
          timeline: true,
          onResourceSelected: (resource) => selected = resource,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text("Welcome dialogue").first);
    await tester.pump(const Duration(milliseconds: 300));

    expect(selected?.value, "cue:dialogue");
    expect(find.byType(AuthoredResourceEditor), findsOneWidget);
    expect(find.text("Welcome dialogue"), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
