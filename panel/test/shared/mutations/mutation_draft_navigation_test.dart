import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../support/test_utils.dart";

void main() {
  testWidgets(
    "return action follows current selection without replacing review fallback",
    (tester) async {
      final container = ProviderContainer.test();
      final workspace = LocalWorkSession();

      addTearDown(workspace.dispose);

      final identity = ServiceIdentifier(
        skir.RecordId(
          table: "service",
          key: skir.RecordIdKey.wrapString("host"),
        ),
      );
      final router = container.read(appRouterProvider);
      final key = EditorResourceKey(scope: null, identity: identity.resourceId);
      final owner = workspace.editor(
        fakeEditorTarget(
          targetId: identity,
          label: "Host configuration",
          document: const EditorDocument(
            rootType: StringType(),
            typeCatalog: TypeCatalog([]),
            confirmedValue: StringValue("original"),
            revision: 1,
          ),
          validation: acceptTestEditorMutation,
          commitPolicy: EditorCommitPolicy.applyResource,
          commit: (change) async =>
              MutationSuccess(revision: 2, value: change.rootValue),
        ),
      );
      workspace.retain(key);
      owner.update(DataPath.root, const StringValue("draft"));

      final resource = workspace.resources[key]!
        ..destination = InspectorDestination(
          container: container,
          router: router,
          path: router.currentPath,
          identity: identity,
        );
      container.read(selectionProvider.notifier).selectAll([identity]);

      await tester.pumpTestApp(
        child: Scaffold(
          appBar: AppBar(
            actions: [LocalWorkSessionActivityView(controller: workspace)],
          ),
        ),
      );

      await tester.tap(find.text("1 draft"));
      await tester.pumpAndSettle();
      expect(find.text("Return to draft"), findsNothing);
      expect(find.text("Review draft"), findsNothing);

      container.read(selectionProvider.notifier).clear();
      await tester.pumpAndSettle();
      expect(find.text("Return to draft"), findsOneWidget);

      await tester.tap(find.text("Return to draft"));
      await tester.pumpAndSettle();
      expect(container.read(selectionProvider), [identity]);
      expect(find.text("Save activity"), findsNothing);
      expect(
        owner.value(DataPath.root).valueOrNull,
        const StringValue("draft"),
      );

      await tester.tap(find.text("1 draft"));
      await tester.pumpAndSettle();
      expect(find.text("Return to draft"), findsNothing);

      await tester.tap(find.byTooltip("Close"));
      await tester.pumpAndSettle();
      resource.destination = null;

      await tester.tap(find.text("1 draft"));
      await tester.pumpAndSettle();
      expect(find.text("Review draft"), findsOneWidget);

      await tester.tap(find.text("Discard"));
      await tester.pumpAndSettle();
      expect(find.text("No pending changes"), findsOneWidget);

      await tester.tap(find.byTooltip("Close"));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  test("matching selection on another route is not the destination", () {
    final container = ProviderContainer.test();
    final identity = ServiceIdentifier(
      skir.RecordId(table: "service", key: skir.RecordIdKey.wrapString("host")),
    );
    container.read(selectionProvider.notifier).selectAll([identity]);
    final destination = InspectorDestination(
      container: container,
      router: container.read(appRouterProvider),
      path: "/another-route",
      identity: identity,
    );
    addTearDown(destination.dispose);
    expect(destination.isCurrent, isFalse);
  });
}
