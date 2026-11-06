import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

/// The open Page, the concrete Sequence, Static, Scene and Manifest
/// pages refining it, and an unrelated type.
final _pageKinds = authoredCatalog([
  declaredRecord("Page", open: true),
  for (final (kind, icon, argb) in [
    ("Sequence", "account-tree", 0xff2196f3),
    ("Static", "push-pin", 0xff673ab7),
    ("Scene", "movie", 0xffff9800),
    ("Manifest", "schema", 0xff4caf50),
  ])
    declaredRecord(
      "${kind}Page",
      parents: ["Page"],
      display: typeDisplay(
        kind,
        description: "$kind page",
        icon: "material-symbols:$icon",
        argb: argb,
      ),
    ),
  declaredRecord("Unrelated"),
], generation: "catalog:resources");

/// Rewards, and CoinReward, a concrete Reward.
final _rewards = [
  declaredRecord("Reward"),
  declaredRecord("CoinReward", parents: ["Reward"]),
];

/// The generic Variable of one parameter T bounded by Reward.
final _variableOfReward = authoredCatalog([
  declaredRecord(
    "Variable",
    parameters: {
      "T": ["Reward"],
    },
  ),
  ..._rewards,
]);

void main() {
  testWidgets("chooses only concrete resource descendants", (tester) async {
    final (chooser, picked) = await TypeChooserDriver.openConcrete(
      tester,
      "Create page",
      expected: testTypeId("Page"),
      catalog: _pageKinds,
    );

    expect(find.text("Search resource types"), findsOneWidget);
    expect(find.text("Page"), findsNothing);
    expect(find.text("Unrelated"), findsNothing);
    expect(find.text("Sequence"), findsOneWidget);
    expect(find.text("Static"), findsOneWidget);
    expect(find.text("Scene"), findsOneWidget);
    expect(find.text("Manifest"), findsOneWidget);
    expect(find.text("Sequence page"), findsOneWidget);

    await chooser.search("manifest");
    expect(find.text("Sequence"), findsNothing);
    expect(find.text("Manifest"), findsOneWidget);
    expect(find.text("Continue"), findsNothing);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final complete = switch (picked.result) {
      skir.TypeSelection_completeWrapper(:final value) => value,
      _ => throw TestFailure("Expected a complete resource selection"),
    };
    expect(complete.definition, testTypeId("ManifestPage"));
  });

  testWidgets("shows no matches and Escape cancels type search", (
    tester,
  ) async {
    final (chooser, picked) = await TypeChooserDriver.openConcrete(
      tester,
      "Create page",
      expected: testTypeId("Page"),
      catalog: _pageKinds,
    );
    await chooser.search("missing page kind");
    expect(find.text("No results found"), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(QueryBar), findsOneWidget);
    expect(chooser.searchFocused, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(QueryBar), findsNothing);
    expect(picked.result, isNull);
  });

  testWidgets("searches scalar arguments and composes a nullable generic", (
    tester,
  ) async {
    final catalog = authoredCatalog([
      declaredRecord("List", parameters: {"T": []}),
      ..._rewards,
    ]);
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
                catalog: catalog,
              );
            },
            child: const Text("Choose payload"),
          ),
        ),
      ),
    );

    await tester.tap(find.text("Choose payload"));
    await tester.pumpAndSettle();
    final chooser = TypeChooserDriver(tester);
    await chooser.search("List");
    await tester.tap(find.text("List<Unfilled>"));
    await tester.pumpAndSettle();

    expect(find.text("Choose payload type"), findsOneWidget);
    await tester.tap(find.text("T: Choose a type"));
    await tester.pumpAndSettle();
    await chooser.search("Text");
    expect(chooser.result("Text"), findsOneWidget);
    expect(chooser.result("Text?"), findsOneWidget);
    await tester.tap(chooser.result("Text"));
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
    expect(named.definition, testTypeId("List"));
    expect(named.arguments, [skir.TypeUse.wrapScalar(skir.ScalarKind.text)]);
  });

  testWidgets("composes arguments and confirms the Realm repair preview", (
    tester,
  ) async {
    skir.TypeSelection? requested;
    skir.TypeArgumentChangePreview? committed;
    String? status;

    await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        Scaffold(
          body: AuthoredTypeArgumentEditor(
            selection: skir.TypeSelection.createPending(
              definition: testTypeId("Variable"),
              arguments: [skir.ArgumentSelection.unfilled],
            ),
            catalog: _variableOfReward,
            preview: (next) async {
              requested = next;
              return readyTypeArgumentPreview(
                _variableOfReward,
                next,
                cleared: [
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

    await TypeChooserDriver(tester).choose("CoinReward");

    expect(find.text("Review type change"), findsOne);
    await tester.tap(find.widgetWithText(FilledButton, "Review type change"));
    await tester.pumpAndSettle();

    final complete = switch (requested) {
      final skir.TypeSelection_completeWrapper value => value,
      _ => throw TestFailure("Expected a complete selection"),
    };
    expect(complete.value.definition, testTypeId("Variable"));
    expect(
      (complete.value.arguments.single as skir.TypeUse_namedWrapper)
          .value
          .definition,
      testTypeId("CoinReward"),
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
    final catalog = authoredCatalog([
      declaredRecord(
        "Variable",
        parameters: {
          "T": ["Reward"],
          "U": ["Reward"],
        },
      ),
      ..._rewards,
    ]);
    skir.TypeSelection? requested;
    await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        Scaffold(
          body: AuthoredTypeArgumentEditor(
            selection: skir.TypeSelection.createPending(
              definition: testTypeId("Variable"),
              arguments: [
                skir.ArgumentSelection.unfilled,
                skir.ArgumentSelection.unfilled,
              ],
            ),
            catalog: catalog,
            preview: (next) async {
              requested = next;
              return readyTypeArgumentPreview(catalog, next);
            },
            commit: (_) async => const EditStageResult.staged(EditGroupId(1)),
          ),
        ),
      ),
    );

    await tester.tap(find.text("Choose a type").first);
    await tester.pumpAndSettle();
    await TypeChooserDriver(tester).choose("CoinReward");
    await tester.tap(find.widgetWithText(FilledButton, "Review type change"));
    await tester.pumpAndSettle();

    final pending = switch (requested) {
      final skir.TypeSelection_pendingWrapper value => value,
      _ => throw TestFailure("Expected a pending selection"),
    };
    expect(pending.value.definition, testTypeId("Variable"));
    expect(
      pending.value.arguments.first,
      isA<skir.ArgumentSelection_chosenWrapper>(),
    );
    expect(pending.value.arguments.last, skir.ArgumentSelection.unfilled);
    expect(find.textContaining("Unfilled"), findsOneWidget);
  });
}
