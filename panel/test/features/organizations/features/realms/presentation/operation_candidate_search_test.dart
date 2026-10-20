import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../support/authored_graph_fixture.dart";
import "../../../../../support/test_utils.dart";

void main() {
  testWidgets(
    "an operation form searches the declared candidates of a resource field",
    (tester) async {
      final fixture = AuthoredGraphFixture(candidateSearch: true);
      final requests = <skir.RealmPresentationSearchRequest>[];
      await _pump(
        tester,
        fixture,
        watchSearch: (request) {
          requests.add(request);
          return Stream.value(
            skir.RealmPresentationSearchUpdate.createSnapshot(
              subscriptionId: request.subscriptionId,
              status: skir.RealmPresentationSearchStatus.ready,
              values: [fixture.option(fixture.destination, "Destination page")],
              guidance: const [],
              diagnostics: const [],
            ),
          );
        },
      );
      await tester.tap(
        find.byKey(ValueKey(fixture.source)),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text("Move to"));
      await tester.pumpAndSettle();

      final form = find.byType(AlertDialog);
      final search = find.descendant(
        of: form,
        matching: find.byType(PortableSearchInput),
      );
      expect(search, findsOneWidget);
      await tester.tap(
        find.descendant(
          of: search,
          matching: find.byKey(const ValueKey("authored_search_summary")),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(QueryBar),
          matching: find.byType(EditableText),
        ),
        "Dest",
      );
      await tester.pumpAndSettle();
      expect(requests, isNotEmpty);
      expect(
        requests.last.capabilityId,
        AuthoredGraphFixture.moveCandidateSearch,
      );
      expect(requests.last.operationContext, isNotNull);
      expect(requests.last.operationContext!.invocation.targets, [
        fixture.source,
      ]);
      expect(find.text("Destination page"), findsWidgets);
      // The candidate is chosen with the keyboard, like every drop offer.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.tap(find.text("Submit"));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        fixture.preparations.last.input
            ?.authoredField("destination")
            ?.authoredString,
        fixture.destination.value,
      );
      expect(
        fixture.workspace.document.relations.children[fixture.destination],
        contains(fixture.source),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      fixture.workspace.dispose();
    },
  );

  testWidgets("fields without candidates keep their default controls", (
    tester,
  ) async {
    final fixture = AuthoredGraphFixture();
    await _pump(tester, fixture);
    await tester.tap(
      find.byKey(ValueKey(fixture.source)),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text("Move to"));
    await tester.pumpAndSettle();
    final form = find.byType(AlertDialog);
    expect(
      find.descendant(of: form, matching: find.byType(PortableSearchInput)),
      findsNothing,
    );
    expect(
      find.descendant(of: form, matching: find.byType(TextField)),
      findsOneWidget,
    );
    await tester.tap(find.text("Cancel"));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    fixture.workspace.dispose();
  });
}

Future<void> _pump(
  WidgetTester tester,
  AuthoredGraphFixture fixture, {
  Stream<skir.RealmPresentationSearchUpdate> Function(
    skir.RealmPresentationSearchRequest,
  )?
  watchSearch,
}) async {
  final base = fixture.commands;
  final commands = AuthoredResourceCommands(
    previewTypeArguments: base.previewTypeArguments,
    prepareTypeArguments: base.prepareTypeArguments,
    prepareValue: base.prepareValue,
    prepareStep: base.prepareStep,
    invokeCommand: base.invokeCommand,
    watchSearch: watchSearch ?? base.watchSearch,
    search: base.search,
    reload: base.reload,
    resolveResourceOperations: base.resolveResourceOperations,
    resolveDropCandidates: base.resolveDropCandidates,
    prepareAuthoringAction: base.prepareAuthoringAction,
  );
  await tester.pumpTestApp(
    overrides: [
      realmInteractionProvider.overrideWithValue(
        const RealmInteractionState(
          connectionState: RealmConnectionState.online,
        ),
      ),
      ...authoringFixtureOverrides(
        scope: fixture.scope,
        transport: fixture.transport,
        commands: commands,
      ),
      realmEditingProvider.overrideWith((ref, scope) => fixture.workspace),
    ],
    child: Center(
      child: SizedBox(
        key: ValueKey(fixture.source),
        width: 160,
        height: 80,
        child: AuthoredResourceItem(
          identifier: fixture.drag.primary,
          resources: AuthoredResourcesContext(
            authoringScope: fixture.scope,
            binding: null,
            scope: PortablePresentationScope(
              bindings: const {},
              operations: testPortableOperations(),
              budget: skir.EvaluationBudget(
                maxSteps: 100,
                maxCollectionItems: 10,
              ),
            ),
            canMutate: () => true,
          ),
          child: const Text("Source"),
        ),
      ),
    ),
  );
}
