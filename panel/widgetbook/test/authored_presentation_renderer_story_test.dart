import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/presentation/authored_presentation_renderer.stories.dart";

void main() {
  testWidgets(
    "heading gallery fits and hides resource identity for multiple selection",
    (tester) async {
      await tester.pumpWidget(
        const FakeApp(
          child: Scaffold(
            body: Center(
              child: SizedBox(width: 200, child: ResourceHeadingGallery()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AutoSizeText), findsNWidgets(2));
      expect(
        find.text("book:019d1c2a8f7b7cc18c2a4a7b2fd1e281"),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        const FakeApp(
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: ResourceHeadingGallery(multiple: true),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AutoSizeText), findsOneWidget);
      expect(find.text("book:019d1c2a8f7b7cc18c2a4a7b2fd1e281"), findsNothing);
      expect(
        find.text("Normal fields and section labels remain visible"),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("the canonical scalar gallery renders and edits real controls", (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const FakeApp(
        child: Scaffold(
          body: SingleChildScrollView(child: AuthoredScalarGallery()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PortablePresentationNodeRenderer), findsWidgets);
    expect(find.text("Title"), findsOneWidget);
    expect(find.text("Count"), findsOneWidget);
    expect(find.text("Enabled"), findsOneWidget);
    expect(find.text("Intensity"), findsOneWidget);
    expect(find.text("Starts at"), findsOneWidget);
    expect(find.text("Duration in milliseconds"), findsOneWidget);
    expect(find.text("Color"), findsOneWidget);
    expect(find.text("Binary payload"), findsOneWidget);
    expect(find.byType(DateTimePickerField), findsOneWidget);
    expect(find.byType(ColorPickerField), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    final count = find.byType(TextFormField).at(1);
    await tester.enterText(count, "12");
    await tester.pumpAndSettle();
    expect(find.text("12"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("canonical layouts and actions preserve interactive behavior", (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(700, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const FakeApp(
        child: Scaffold(
          body: SingleChildScrollView(child: AuthoredInteractionGallery()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Details are visible"), findsOneWidget);
    expect(find.byType(DepthBox), findsWidgets);
    expect(find.text("Quest actions"), findsOneWidget);
    expect(
      find.text("Portable header actions use the current draft"),
      findsOneWidget,
    );
    expect(
      find.byTooltip("The presentation value is unavailable"),
      findsOneWidget,
    );
    expect(
      tester.getCenter(find.widgetWithText(TextButton, "Archive")).dx,
      greaterThan(
        tester.getCenter(find.widgetWithText(TextButton, "Duplicate")).dx,
      ),
    );
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text("Details are hidden"), findsOneWidget);

    expect(find.text("General settings"), findsOneWidget);
    await tester.tap(find.text("Advanced"));
    await tester.pumpAndSettle();
    expect(find.text("Advanced settings"), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, "History"));
    await tester.pumpAndSettle();
    expect(find.text("Change history"), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, "Add item").last);
    await tester.pumpAndSettle();
    expect(find.text("Item 4"), findsOneWidget);
    expect(find.byTooltip("Remove item"), findsNWidgets(4));

    final firstItem = find.text("Item 1");
    final secondItem = find.text("Item 2");
    expect(
      tester.getTopLeft(firstItem).dy,
      lessThan(tester.getTopLeft(secondItem).dy),
    );
    await tester.tap(find.byTooltip("Reorder item").first);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(firstItem).dy,
      greaterThan(tester.getTopLeft(secondItem).dy),
    );

    await tester.tap(find.widgetWithText(FilledButton, "Add entry").last);
    await tester.pumpAndSettle();
    expect(find.text("chapter"), findsOneWidget);
    expect(find.text("Arrival"), findsOneWidget);
    expect(find.byTooltip("Remove row"), findsNWidgets(3));

    await tester.tap(find.widgetWithText(TextButton, "Archive"));
    await tester.pumpAndSettle();
    expect(find.text("Archive quest?"), findsOneWidget);
    expect(
      find.text("The quest will no longer be available to players."),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, "Archive"));
    await tester.pumpAndSettle();
    expect(find.text("Archived quest"), findsOneWidget);

    await tester.tap(find.byTooltip("Collapse"));
    await tester.pumpAndSettle();
    expect(find.text("Archived quest"), findsNothing);
    await tester.tap(find.byTooltip("Expand"));
    await tester.pumpAndSettle();
    expect(find.text("Archived quest"), findsOneWidget);

    final reload = find.widgetWithText(FilledButton, "Reload from Realm");
    await tester.ensureVisible(reload);
    await tester.pumpAndSettle();
    await tester.tap(reload);
    await tester.pumpAndSettle();
    expect(find.text("Reload is unavailable"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
