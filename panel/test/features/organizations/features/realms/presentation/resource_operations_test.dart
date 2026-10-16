import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../support/test_utils.dart";

void main() {
  testWidgets("declared navigation confirmation can cancel before opening", (
    tester,
  ) async {
    final adapter = _Navigation();
    await _pump(tester, adapter, confirmation: true);
    await tester.tap(
      find.byKey(ValueKey(_first)),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text("Open"));
    await tester.pumpAndSettle();
    expect(adapter.opened, isEmpty);
    await tester.tap(find.text("Cancel"));
    await tester.pumpAndSettle();
    expect(adapter.opened, isEmpty);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets(
    "Edit selects and focuses the inspector without page navigation",
    (tester) async {
      final adapter = _Navigation();
      await _pump(tester, adapter, edit: true);
      await tester.tap(
        find.byKey(ValueKey(_first)),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text("Edit"));
      await tester.pumpAndSettle();
      expect(adapter.opened, isEmpty);
      expect(tester.container().read(selectionProvider), [
        AuthoringResourceIdentifier.inScope(_scope, _first),
      ]);
      final field = tester.widget<TextField>(
        find.byKey(const ValueKey("operation.inspector.input")),
      );
      expect(field.focusNode!.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "Book Open shares its menu, double click and primary keyboard action",
    (tester) async {
      final adapter = _Navigation();
      await _pump(tester, adapter);
      final tile = find.byKey(ValueKey(_first));
      await tester.tap(tile);
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(adapter.opened, [_first]);

      await tester.tap(tile, buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text("Open"));
      await tester.pumpAndSettle();
      expect(adapter.opened, [_first, _first]);

      final selector = tester.widget<Selector>(find.byType(Selector));
      tester.container().read(selectionProvider.notifier).selectAll([
        selector.selectableId,
      ]);
      selector.focusNode.requestFocus();
      await tester.pumpAndSettle();
      final modifier =
          defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.iOS
          ? LogicalKeyboardKey.metaLeft
          : LogicalKeyboardKey.controlLeft;
      await tester.sendKeyDownEvent(modifier);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(modifier);
      await tester.pumpAndSettle();
      expect(adapter.opened, [_first, _first, _first]);
    },
  );

  testWidgets(
    "an open resource menu keeps its targets after global selection changes",
    (tester) async {
      final adapter = _Navigation();
      await _pump(tester, adapter, second: true);
      await tester.tap(
        find.byKey(ValueKey(_first)),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();
      tester.container().read(selectionProvider.notifier).selectAll([
        AuthoringResourceIdentifier.inScope(_scope, _second),
      ]);
      await tester.pumpAndSettle();
      await tester.tap(find.text("Open"));
      await tester.pumpAndSettle();
      expect(adapter.opened, [_first]);
    },
  );

  testWidgets("disabled primary operations cannot run through double click", (
    tester,
  ) async {
    final adapter = _Navigation();
    await _pump(tester, adapter, disabled: true);
    final tile = find.byKey(ValueKey(_first));
    await tester.tap(tile);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(adapter.opened, isEmpty);
    await tester.tap(tile, buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();
    expect(find.text("Open (The book is unavailable)"), findsOneWidget);
  });
}

final _first = skir.ResourceId(value: "book:first");
final _second = skir.ResourceId(value: "book:second");
final _scope = AuthoringScope(
  organizationId: skir.recordId("organization:operations"),
  realmId: skir.recordId("realm:operations"),
);

Future<void> _pump(
  WidgetTester tester,
  _Navigation adapter, {
  bool second = false,
  bool disabled = false,
  bool edit = false,
  bool confirmation = false,
}) async {
  var document = fixtureAuthoringDocument(
    books: [
      for (final id in [_first, if (second) _second])
        Book(
          bookId: id,
          title: id.value,
          icon: "mdi:book",
          color: Colors.blue,
          tagIds: const [],
        ),
    ],
  );
  document = document.copyWith(
    catalog: CheckedEditorCatalog(
      (document.catalog.snapshot.toMutable()
            ..resourceDefinitions = [
              skir.AuthoringResourceDefinition(
                id: coreBookResourceDefinition,
                root:
                    (document.resource(_first)!.configuration
                            as skir.TypeSelection_completeWrapper)
                        .value
                        .definition,
                navigationHandler: skir.AuthoringNavigationHandler.book,
              ),
            ])
          .toFrozen(),
    ),
  );
  final transport = ScriptedAuthoringTransport(AsyncData(document));
  addTearDown(transport.dispose);
  final openId =
      (resourceDeleteOperationId.toMutable()..local = edit ? "edit" : "open")
          .toFrozen();
  final open = skir.ResourceOperationDefinition(
    id: openId,
    targets: skir.OperationTargets.contributedSingle,
    presentation: skir.OperationPresentation(
      label: edit ? "Edit" : "Open",
      description: "Open this book",
      icon: "",
      group: skir.OperationGroup.navigation,
      order: 0,
      tone: skir.HeaderActionTone.neutral,
      confirmation: confirmation
          ? skir.OperationConfirmation(
              title: "Open book",
              message: "Open this book now?",
              confirmationLabel: "Continue",
            )
          : null,
    ),
    action: skir.EditorAction.createNavigate(
      resource: skir.ExpressionNode.createRead(
        binding: skir.ExpressionBindingId(value: "context:subject"),
        path: editorRootPath,
      ),
      mode: edit
          ? skir.ResourceNavigationMode.edit
          : skir.ResourceNavigationMode.open,
    ),
  );
  final commands = fixtureAuthoringCommands(
    transport,
    resolveResourceOperations: (_) async =>
        skir.ResolveResourceOperationsResult.wrapResolved(
          skir.ResolvedResourceOperations(
            operations: [
              skir.ResolvedResourceOperation(
                definition: open,
                availability: disabled
                    ? skir.OperationAvailability.wrapDisabled(
                        "The book is unavailable",
                      )
                    : skir.OperationAvailability.enabled,
              ),
            ],
            primaryOperation: openId,
          ),
        ),
  );
  await tester.pumpTestApp(
    overrides: [
      ...authoringFixtureOverrides(
        scope: _scope,
        transport: transport,
        commands: commands,
      ),
      authoringResourceNavigationRegistryProvider.overrideWithValue(
        AuthoringResourceNavigationRegistry({
          skir.AuthoringNavigationHandler.book: adapter,
        }),
      ),
    ],
    child: Row(
      children: [
        if (edit)
          Consumer(
            builder: (context, ref, _) {
              final focus = FocusNode();
              addTearDown(focus.dispose);
              return SizedBox(
                width: 180,
                child: PortableLocationRevealScope(
                  presentation: skir.PresentationRole.inspector,
                  controller: ref.watch(realmLocationRevealProvider(_scope)),
                  child: PortableLocationTarget(
                    location: skir.ValueLocation(
                      resource: _first,
                      path: editorRootPath,
                    ),
                    child: TextField(
                      key: const ValueKey("operation.inspector.input"),
                      focusNode: focus,
                    ),
                  ),
                ),
              );
            },
          ),
        for (final id in [_first, if (second) _second])
          BookWidget(
            key: ValueKey(id),
            id: id,
            title: id.value,
            icon: const Icon(Icons.book),
            color: Colors.blue,
          ),
      ],
    ),
  );
}

final class _Navigation implements AuthoringResourceNavigationAdapter {
  final opened = <skir.ResourceId>[];
  @override
  Future<void> open(
    Ref ref,
    AuthoringResourceIdentifier resource, {
    bool Function()? isCurrent,
  }) async {
    if (isCurrent?.call() ?? true) opened.add(resource.resourceId);
  }

  @override
  Future<void> reveal(
    Ref ref,
    AuthoringResourceIdentifier resource, {
    bool Function()? isCurrent,
  }) async {}
}
