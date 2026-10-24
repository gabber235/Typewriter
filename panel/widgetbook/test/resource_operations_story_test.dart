import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/presentation/resource_operation_drop_target.stories.dart";

void main() {
  testWidgets("operation story moves an entry through the shared drop runner", (
    tester,
  ) async {
    await tester.pumpWidget(resourceOperationDropTargetExample(delayed: false));
    await tester.pumpAndSettle();
    final node = find.byType(AuthoredPageGraphNode).first;
    final container = ProviderScope.containerOf(tester.element(node));
    final scope = container.read(selectedAuthoringScopeProvider)!;
    final workspace = container.read(realmEditingProvider(scope));
    final source = tester.getCenter(node);
    final destination = tester.getCenter(find.byType(ResourcePageDropTarget));
    final gesture = await tester.startGesture(source);
    await gesture.moveBy(const Offset(25, 0));
    await tester.pump();
    await gesture.moveTo(destination);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      workspace.document.relations.ownerPath(compiledEntryFirstId).owners.first,
      compiledEntryDestinationId,
    );
    expect(find.byType(AuthoredPageGraphNode), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    "operation story exposes declared menu and transient typed input",
    (tester) async {
      await tester.pumpWidget(
        resourceOperationDropTargetExample(delayed: false),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byType(AuthoredPageGraphNode).first,
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();
      expect(find.text("Edit"), findsOneWidget);
      expect(find.text("Open"), findsNothing);
      await tester.tap(find.text("Move to page"));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.enterText(
        find.byType(TextField).last,
        compiledEntryDestinationId.value,
      );
      await tester.tap(find.text("Submit"));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(AuthoredPageGraphNode), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
