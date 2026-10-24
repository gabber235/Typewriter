import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../support/test_utils.dart";

void main() {
  testWidgets("menus lead with Open and Inspect, then group the operations", (
    tester,
  ) async {
    await _pump(tester, _Navigation());
    await tester.tap(
      find.byKey(ValueKey(_first)),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    final labels = [
      for (final button in find.byType(MenuItemButton).evaluate())
        tester
            .widget<Text>(
              find
                  .descendant(
                    of: find.byWidget(button.widget),
                    matching: find.byType(Text),
                  )
                  .first,
            )
            .data,
    ];
    expect(labels, ["Open", "Inspect", "Duplicate", "Move to", "Delete"]);
    // Navigation, edit, organize and destructive sections.
    expect(find.byType(Divider), findsNWidgets(3));
  });

  testWidgets("the inspector shows the operations declared as buttons", (
    tester,
  ) async {
    await _pump(tester, _Navigation(), showInspector: true);
    tester.container().read(selectionProvider.notifier).selectAll([
      AuthoringResourceIdentifier.inScope(_scope, _first),
    ]);
    await tester.pumpAndSettle();
    final inspector = find.byType(InspectorOperations);
    for (final label in ["Open", "Duplicate", "Delete"]) {
      expect(
        find.descendant(of: inspector, matching: find.text(label)),
        findsOneWidget,
      );
    }
    for (final label in ["Inspect", "Move to"]) {
      expect(
        find.descendant(of: inspector, matching: find.text(label)),
        findsNothing,
      );
    }
    final delete = tester.widget<FilledButton>(
      find.descendant(of: inspector, matching: find.byType(FilledButton)),
    );
    expect(delete.onPressed, isNotNull);
  });

  testWidgets(
    "Open routes through the surface navigator from the menu, double click "
    "and the primary keyboard action",
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
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("Inspect selects and reveals the inspector without navigation", (
    tester,
  ) async {
    final adapter = _Navigation();
    await _pump(tester, adapter, revealTarget: true);
    await tester.tap(
      find.byKey(ValueKey(_first)),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text("Inspect"));
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
  });

  testWidgets(
    "the Delete key runs the operation bound to the delete shortcut and "
    "asks for the confirmation the Realm returns",
    (tester) async {
      final prepared = <skir.CapabilityId>[];
      await _pump(tester, _Navigation(), prepared: prepared);
      final selector = tester.widget<Selector>(find.byType(Selector));
      tester.container().read(selectionProvider.notifier).selectAll([
        selector.selectableId,
      ]);
      selector.focusNode.requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pumpAndSettle();
      expect(prepared, [_capability("Delete")]);
      expect(find.text("Delete the selected resources?"), findsOneWidget);
      await tester.tap(find.text("Cancel"));
      await tester.pumpAndSettle();
      final container = tester.container();
      final document = container
          .read(workingAuthoringDocumentProvider(_scope))
          .requireValue;
      expect(document.resource(_first), isNotNull);

      selector.focusNode.requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, "Delete"));
      await tester.pumpAndSettle();
      expect(
        container
            .read(workingAuthoringDocumentProvider(_scope))
            .requireValue
            .resource(_first),
        isNull,
      );
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

  testWidgets("disabled operations show their reason and cannot run", (
    tester,
  ) async {
    final prepared = <skir.CapabilityId>[];
    await _pump(tester, _Navigation(), disabled: true, prepared: prepared);
    await tester.tap(
      find.byKey(ValueKey(_first)),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text("Duplicate (The book is unavailable)"));
    await tester.pumpAndSettle();
    expect(prepared, isEmpty);
  });
}

final _first = skir.ResourceId(value: "book:first");
final _second = skir.ResourceId(value: "book:second");
final _scope = AuthoringScope(
  organizationId: skir.recordId("organization:operations"),
  realmId: skir.recordId("realm:operations"),
);

skir.ResourceOperationId _id(String name) => skir.ResourceOperationId(
  artifact: "typewriter",
  sourcePart: "main",
  declaration: "com.typewritermc.operations.$name",
);

skir.CapabilityId _capability(String name) =>
    skir.CapabilityId(value: "operations:$name");

/// Duplicate is an edit button, MoveToOwner an organizing drop that stays out
/// of the inspector, and Delete a destructive filled button on the delete
/// key.
skir.ResourceOperationDefinition _definition(String name) {
  final destructive = name == "Delete";
  return skir.ResourceOperationDefinition(
    id: _id(name),
    targets: skir.OperationTargets(
      subject: skir.ResourceTarget.anyResource,
      cardinality: skir.OperationCardinality.selection,
    ),
    capability: _capability(name),
    drop: name == "MoveToOwner"
        ? skir.OperationDrop(
            input: editorRootPath.field("destination"),
            hint: "Move here",
          )
        : null,
    presentation: skir.OperationPresentation(
      label: name == "MoveToOwner" ? "Move to" : name,
      description: "$name the book",
      icon: "",
      group: switch (name) {
        "Duplicate" => skir.OperationGroup.edit,
        "MoveToOwner" => skir.OperationGroup.organize,
        _ => skir.OperationGroup.destructive,
      },
      order: 0,
      tone: destructive
          ? skir.HeaderActionTone.destructive
          : skir.HeaderActionTone.neutral,
      confirmation: null,
      inspector: name == "MoveToOwner"
          ? skir.OperationInspector.hidden
          : skir.OperationInspector.wrapButton(
              destructive
                  ? skir.ButtonVariant.filled
                  : skir.ButtonVariant.outlined,
            ),
      shortcut: destructive ? skir.OperationShortcut.delete : null,
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  _Navigation adapter, {
  bool second = false,
  bool disabled = false,
  bool revealTarget = false,
  bool showInspector = false,
  List<skir.CapabilityId>? prepared,
}) async {
  final books = fixtureAuthoringDocument(
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
  // The operations prepare through authoring capabilities of the catalog.
  final document = books.copyWith(
    catalog: CheckedEditorCatalog(
      (books.catalog.snapshot.toMutable()
            ..capabilities = [
              ...books.catalog.snapshot.capabilities,
              for (final name in ["Duplicate", "MoveToOwner", "Delete"])
                skir.CapabilityDefinition.createAuthoring(
                  capabilityId: _capability(name),
                  targets: _definition(name).targets,
                  input: null,
                ),
            ])
          .toFrozen(),
    ),
  );
  final transport = ScriptedAuthoringTransport(AsyncData(document));
  addTearDown(transport.dispose);
  final commands = fixtureAuthoringCommands(
    transport,
    resolveResourceOperations: (_) async =>
        skir.ResolveResourceOperationsResult.wrapResolved(
          skir.ResolvedResourceOperations(
            operations: [
              for (final name in ["Duplicate", "MoveToOwner", "Delete"])
                skir.ResolvedResourceOperation(
                  definition: _definition(name),
                  availability: disabled
                      ? skir.OperationAvailability.wrapDisabled(
                          "The book is unavailable",
                        )
                      : skir.OperationAvailability.enabled,
                ),
            ],
          ),
        ),
    prepareAuthoringAction: (request) async {
      prepared?.add(request.capability);
      final edit = AuthoringEdit.fromDocument(
        transport.observation.requireValue,
      );
      for (final target in request.invocation.targets) {
        edit.delete(target);
      }
      return skir.AuthoringActionResult.createPreview(
        invocationId: request.invocation.invocationId,
        inputRevision: request.inputRevision,
        edit: edit.prepare(),
        confirmation: skir.OperationConfirmation(
          title: "Delete resources",
          message: "Delete the selected resources?",
          confirmationLabel: "Delete",
        ),
        selection: skir.OperationSelectionEffect.unchanged,
      );
    },
  );
  await tester.pumpTestApp(
    overrides: [
      realmInteractionProvider.overrideWithValue(
        const RealmInteractionState(
          connectionState: RealmConnectionState.online,
        ),
      ),
      ...authoringFixtureOverrides(
        scope: _scope,
        transport: transport,
        commands: commands,
      ),
      realmSurfaceNavigationProvider.overrideWith(
        (ref) => _RecordingNavigation(ref, adapter),
      ),
    ],
    child: SelectionOperationShortcuts(
      child: Row(
        children: [
          if (showInspector)
            const SizedBox(width: 180, child: InspectorOperations()),
          if (revealTarget)
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
            SizedBox(
              key: ValueKey(id),
              width: 120,
              height: 80,
              child: AuthoredResourceItem(
                identifier: AuthoringResourceIdentifier.inScope(_scope, id),
                resources: AuthoredResourcesContext(
                  authoringScope: _scope,
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
                child: Text(id.value),
              ),
            ),
        ],
      ),
    ),
  );
}

/// The resources a test saw opened.
final class _Navigation {
  final opened = <skir.ResourceId>[];
}

/// Records surface openings instead of navigating.
final class _RecordingNavigation extends RealmSurfaceNavigation {
  _RecordingNavigation(super.ref, this.recorded);

  final _Navigation recorded;

  @override
  Future<bool> open(
    AuthoringScope scope,
    skir.ResourceId resource, {
    bool Function()? isCurrent,
  }) async {
    if (isCurrent?.call() ?? true) recorded.opened.add(resource);
    return true;
  }
}
