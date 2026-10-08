import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/presentation/authored_resource_editor.stories.dart";

void main() {
  for (final size in [
    const Size(390, 844),
    const Size(844, 390),
    const Size(1024, 768),
    const Size(1440, 1200),
  ]) {
    testWidgets("new draft editor fits ${size.width} by ${size.height}", (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(Builder(builder: authoredNewDraftUseCase));
      await tester.pumpAndSettle();

      expect(find.byType(AuthoredResourceEditor), findsOneWidget);
      expect(find.text("Search page types"), findsOneWidget);
      expect(find.text("Title"), findsOneWidget);
      expect(find.widgetWithText(TextButton, "Cancel"), findsNothing);
      expect(find.widgetWithText(FilledButton, "Create"), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets("edits an unfinished value through the normal editor", (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(Builder(builder: authoredNewDraftUseCase));
    await tester.pumpAndSettle();

    final title = find.byType(TextFormField).first;
    expect(title, findsOneWidget);
    expect(tester.widget<TextFormField>(title).controller?.text, isEmpty);
    await tester.enterText(title, "Meet the mayor");
    await tester.pumpAndSettle();
    expect(find.text("Meet the mayor"), findsOneWidget);

    expect(find.byType(AuthoredResourceEditor), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("searches page kinds without a precreation editor", (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(Builder(builder: authoredNewDraftUseCase));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Search page types"));
    await tester.pumpAndSettle();
    expect(find.text("Sequence"), findsOneWidget);
    expect(find.text("Static"), findsOneWidget);
    expect(find.text("Scene"), findsOneWidget);
    expect(find.text("Manifest"), findsOneWidget);

    await tester.tap(find.text("Static"));
    await tester.pumpAndSettle();
    expect(find.text("Selected Static"), findsOneWidget);
    expect(find.byType(AuthoredResourceEditor), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
