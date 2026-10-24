import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/presentation/resource_drop_target.stories.dart";

void main() {
  testWidgets(
    "drop story moves an entry through the operation its drop offers",
    (tester) async {
      await tester.pumpWidget(resourceDropTargetExample());
      await tester.pumpAndSettle();
      final node = find.byType(AuthoredGraphItem).first;
      final container = ProviderScope.containerOf(tester.element(node));
      final scope = container.read(selectedAuthoringScopeProvider)!;
      final workspace = container.read(realmEditingProvider(scope));
      final source = tester.getCenter(node);
      final destination = tester.getCenter(
        find.ancestor(
          of: find.byKey(const ValueKey("story.destination")),
          matching: find.byType(ResourceDropHighlight),
        ),
      );
      final gesture = await tester.startGesture(source);
      await gesture.moveBy(const Offset(25, 0));
      await tester.pump();
      await gesture.moveTo(destination);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        workspace.document.relations
            .ownerPath(compiledEntryFirstId)
            .owners
            .first,
        compiledEntryDestinationId,
      );
      expect(find.byType(AuthoredGraphItem), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("drop story keeps every drop offer reachable from the menu", (
    tester,
  ) async {
    await tester.pumpWidget(resourceDropTargetExample());
    await tester.pumpAndSettle();
    await tester.tap(
      find.byType(AuthoredGraphItem).first,
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    expect(find.text("Open"), findsOneWidget);
    expect(find.text("Inspect"), findsOneWidget);
    await tester.tap(find.text("Move to"));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.enterText(
      find.byType(TextField).last,
      compiledEntryDestinationId.value,
    );
    await tester.tap(find.text("Submit"));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(AuthoredGraphItem), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
