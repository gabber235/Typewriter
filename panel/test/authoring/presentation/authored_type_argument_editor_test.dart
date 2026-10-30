import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("chooses only concrete resource descendants", (tester) async {
    final fixture = PageKindsFixture();
    skir.TypeSelection? selected;

    await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              selected = await showCreationConcreteTypePicker(
                context,
                expected: skir.TypeSelection.createComplete(
                  definition: fixture.page,
                  arguments: const [],
                ),
                catalog: fixture.catalog,
              );
            },
            child: const Text("Create page"),
          ),
        ),
      ),
    );

    await tester.tap(find.text("Create page"));
    await tester.pumpAndSettle();

    expect(find.text("Search resource types"), findsOneWidget);
    expect(find.text("Page"), findsNothing);
    expect(find.text("Unrelated"), findsNothing);
    expect(find.text("Sequence"), findsOneWidget);
    expect(find.text("Static"), findsOneWidget);
    expect(find.text("Scene"), findsOneWidget);
    expect(find.text("Manifest"), findsOneWidget);
    expect(find.text("Sequence page"), findsOneWidget);

    final query = find.descendant(
      of: find.byType(QueryBar),
      matching: find.byType(EditableText),
    );
    await tester.enterText(query, "manifest");
    await tester.pumpAndSettle();
    expect(find.text("Sequence"), findsNothing);
    expect(find.text("Manifest"), findsOneWidget);
    expect(find.text("Continue"), findsNothing);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final complete = switch (selected) {
      skir.TypeSelection_completeWrapper(:final value) => value,
      _ => throw TestFailure("Expected a complete resource selection"),
    };
    expect(complete.definition, fixture.manifest);
  });

  testWidgets("shows no matches and Escape cancels type search", (
    tester,
  ) async {
    final fixture = PageKindsFixture();
    skir.TypeSelection? selected;

    await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              selected = await showCreationConcreteTypePicker(
                context,
                expected: skir.TypeSelection.createComplete(
                  definition: fixture.page,
                  arguments: const [],
                ),
                catalog: fixture.catalog,
              );
            },
            child: const Text("Create page"),
          ),
        ),
      ),
    );

    await tester.tap(find.text("Create page"));
    await tester.pumpAndSettle();
    final query = find.descendant(
      of: find.byType(QueryBar),
      matching: find.byType(EditableText),
    );
    await tester.enterText(query, "missing page kind");
    await tester.pumpAndSettle();
    expect(find.text("No results found"), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(QueryBar), findsOneWidget);
    expect(
      tester.widget<EditableText>(query).focusNode.hasPrimaryFocus,
      isFalse,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(QueryBar), findsNothing);
    expect(selected, isNull);
  });

  testWidgets("searches scalar arguments and composes a nullable generic", (
    tester,
  ) async {
    final fixture = RewardContainerFixture(
      unbounded: true,
      containerName: "List",
    );
    skir.TypeUse? selected;

    await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              selected = await showAuthoredTypeUsePicker(
                context,
                title: "Choose payload type",
                catalog: fixture.catalog,
              );
            },
            child: const Text("Choose payload"),
          ),
        ),
      ),
    );

    await tester.tap(find.text("Choose payload"));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(QueryBar),
        matching: find.byType(EditableText),
      ),
      "List",
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text("List<Unfilled>"));
    await tester.pumpAndSettle();

    expect(find.text("Choose payload type"), findsOneWidget);
    await tester.tap(find.text("T: Choose a type"));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(QueryBar),
        matching: find.byType(EditableText),
      ),
      "Text",
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(SearchResultCard),
        matching: find.text("Text"),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(SearchResultCard),
        matching: find.text("Text?"),
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(
        of: find.byType(SearchResultCard),
        matching: find.text("Text"),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text("Allow no value"));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, "Choose"));
    await tester.pumpAndSettle();

    final nullable = switch (selected) {
      skir.TypeUse_nullableWrapper(:final value) => value.value,
      _ => throw TestFailure("Expected a nullable type"),
    };
    final named = switch (nullable) {
      skir.TypeUse_namedWrapper(:final value) => value,
      _ => throw TestFailure("Expected a named generic type"),
    };
    expect(named.definition, fixture.container);
    expect(named.arguments, [skir.TypeUse.wrapScalar(skir.ScalarKind.text)]);
  });

  testWidgets("composes arguments and confirms the Realm repair preview", (
    tester,
  ) async {
    final fixture = RewardContainerFixture();
    skir.TypeSelection? requested;
    skir.TypeArgumentChangePreview? committed;
    String? status;

    await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        Scaffold(
          body: AuthoredTypeArgumentEditor(
            selection: skir.TypeSelection.createPending(
              definition: fixture.container,
              arguments: [skir.ArgumentSelection.unfilled],
            ),
            catalog: fixture.catalog,
            preview: (next) async {
              requested = next;
              return skir.PreviewTypeArgumentChangeResponse.createReady(
                resource: skir.ResourceId(value: "variable:1"),
                next: next,
                edit: skir.PreparedEdit(
                  catalog: fixture.catalog.snapshot.generation,
                  expectations: const [],
                  intents: const [],
                ),
                linkRepairs: const [],
                clearedLocations: [
                  skir.ValueLocation(
                    resource: skir.ResourceId(value: "variable:1"),
                    path: skir.ValuePath(
                      segments: [skir.PathSegment.createField(name: "value")],
                    ),
                  ),
                ],
              );
            },
            commit: (preview) async {
              committed = preview;
              return const EditStageResult.staged(EditGroupId(1));
            },
            onStatus: (value) => status = value,
          ),
        ),
      ),
    );

    expect(find.textContaining("independent fields remain editable"), findsOne);
    await tester.tap(find.text("Choose a type"));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(
        of: find.byType(QueryBar),
        matching: find.byType(EditableText),
      ),
      "CoinReward",
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(SearchResultCard),
        matching: find.text("CoinReward"),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Review type change"), findsOne);
    await tester.tap(find.widgetWithText(FilledButton, "Review type change"));
    await tester.pumpAndSettle();

    final complete = switch (requested) {
      final skir.TypeSelection_completeWrapper value => value,
      _ => throw TestFailure("Expected a complete selection"),
    };
    expect(complete.value.definition, fixture.container);
    expect(
      (complete.value.arguments.single as skir.TypeUse_namedWrapper)
          .value
          .definition,
      fixture.coin,
    );
    expect(find.text("Values cleared: 1"), findsOne);
    expect(find.textContaining("variable:1 value"), findsOne);

    await tester.tap(find.widgetWithText(FilledButton, "Apply type change"));
    await tester.pumpAndSettle();

    expect(committed?.next, requested);
    expect(status, "Type arguments staged");
  });

  testWidgets("persists one chosen argument while another stays Unfilled", (
    tester,
  ) async {
    final fixture = RewardContainerFixture(parameterCount: 2);
    skir.TypeSelection? requested;
    await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        Scaffold(
          body: AuthoredTypeArgumentEditor(
            selection: skir.TypeSelection.createPending(
              definition: fixture.container,
              arguments: [
                skir.ArgumentSelection.unfilled,
                skir.ArgumentSelection.unfilled,
              ],
            ),
            catalog: fixture.catalog,
            preview: (next) async {
              requested = next;
              return skir.PreviewTypeArgumentChangeResponse.createReady(
                resource: skir.ResourceId(value: "variable:1"),
                next: next,
                edit: skir.PreparedEdit(
                  catalog: fixture.catalog.snapshot.generation,
                  expectations: const [],
                  intents: const [],
                ),
                linkRepairs: const [],
                clearedLocations: const [],
              );
            },
            commit: (_) async => const EditStageResult.staged(EditGroupId(1)),
          ),
        ),
      ),
    );

    await tester.tap(find.text("Choose a type").first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(QueryBar),
        matching: find.byType(EditableText),
      ),
      "CoinReward",
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(SearchResultCard),
        matching: find.text("CoinReward"),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, "Review type change"));
    await tester.pumpAndSettle();

    final pending = switch (requested) {
      final skir.TypeSelection_pendingWrapper value => value,
      _ => throw TestFailure("Expected a pending selection"),
    };
    expect(pending.value.definition, fixture.container);
    expect(
      pending.value.arguments.first,
      isA<skir.ArgumentSelection_chosenWrapper>(),
    );
    expect(pending.value.arguments.last, skir.ArgumentSelection.unfilled);
    expect(find.textContaining("Unfilled"), findsOneWidget);
  });
}
