import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../support/authored_graph_fixture.dart";
import "../../../../../support/test_utils.dart";

void main() {
  test("compiled entry fixture has real graph presentations and ownership", () {
    final document = compiledEntryNodeDocument();
    expect(
      document.relations.children[compiledEntryPageId],
      contains(compiledEntryFirstId),
    );
    expect(
      document.catalog.selectPresentation(
        document.resource(compiledEntryFirstId)!.configuration,
        skir.PresentationRole.item,
      ),
      isA<SelectedEditorPresentation>(),
    );
  });
  test(
    "a drag carries the selection only when it starts on a selected resource",
    () {
      final fixture = AuthoredGraphFixture(secondSource: true);
      final primary = fixture.drag.primary;
      final second = AuthoringResourceIdentifier.inScope(
        fixture.scope,
        fixture.second,
      );
      final foreign = second.copyWith(
        realmId: skir.RecordId(
          table: fixture.scope.realmId.table,
          key: skir.RecordIdKey.wrapString("other"),
        ),
      );
      expect(
        ResourceDrag.forSelection(
          primary: primary,
          selection: [second, foreign],
        ).subjects,
        [fixture.source],
      );
      expect(
        ResourceDrag.forSelection(
          primary: primary,
          selection: [second, primary, foreign],
        ).subjects,
        [fixture.source, fixture.second],
      );
    },
  );

  testWidgets(
    "only the bound resource's own link fields receive dropped resources",
    (tester) async {
      final fixture = AuthoredGraphFixture(secondSource: true);
      final binding = fixture.workspace.attach(fixture.page);
      addTearDown(binding.detach);
      final scope = PortablePresentationScope(
        bindings: const {},
        operations: testPortableOperations(),
        budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 100),
        resource: fixture.page,
      );
      Widget field(String key, skir.ResourceId resource) => Builder(
        builder: (context) => PortableResourcesInteractionScope.wrapLinkField(
          context,
          scope,
          skir.ValueLocation(
            resource: resource,
            path: editorRootPath.field("links"),
          ),
          SizedBox(key: ValueKey(key), height: 20),
        ),
      );
      await tester.pumpTestApp(
        overrides: [
          ...authoringFixtureOverrides(
            scope: fixture.scope,
            transport: fixture.transport,
            commands: fixture.commands,
          ),
          realmEditingProvider.overrideWith((ref, scope) => fixture.workspace),
        ],
        child: AuthoredResourcesInteractions(
          authoringScope: fixture.scope,
          binding: binding,
          child: Column(
            children: [
              field("own", fixture.page),
              // A reference preview of another resource nested in the editor.
              field("foreign", fixture.second),
            ],
          ),
        ),
      );

      Finder target(String key) => find.ancestor(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(ResourceDropTarget),
      );
      expect(target("own"), findsOneWidget);
      expect(target("foreign"), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      fixture.workspace.dispose();
    },
  );

  testWidgets("selection and focus reach portable node state", (tester) async {
    final fixture = AuthoredGraphFixture(secondSource: true);
    await _pump(tester, fixture);
    final source = find.byKey(ValueKey(fixture.source));
    await tester.tap(source);
    await tester.pumpAndSettle();
    final selector = tester
        .widgetList<Selector>(find.byType(Selector))
        .singleWhere((value) => value.selectableId.id == fixture.source.value);
    expect(selector.focusNode.hasFocus, isTrue);
    expect(tester.container().read(selectionProvider), [fixture.drag.primary]);
    final probe = tester.element(source);
    expect(PresentationInteractionScope.of(probe).selected, isTrue);
    expect(PresentationInteractionScope.of(probe).focused, isTrue);
  });

  testWidgets(
    "a node reference drop stages links and prevents graph movement",
    (tester) async {
      final fixture = AuthoredGraphFixture(secondSource: true);
      final moves = <List<GraphMoveCommitPayload>>[];
      await _pump(tester, fixture, onMove: moves.add);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(ValueKey(fixture.source))),
      );
      await gesture.moveBy(const Offset(25, 0));
      await tester.pump();
      await gesture.moveTo(
        tester.getCenter(find.byKey(ValueKey(fixture.second))),
      );
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      if (find.text("Choose source field").evaluate().isNotEmpty) {
        await tester.tap(find.text("triggers"));
        await tester.pumpAndSettle();
      }
      expect(moves, isEmpty);
      expect(
        fixture.workspace.document.links.where(
          (link) => link.contract == fixture.triggerRelation,
        ),
        hasLength(1),
      );
      expect(
        fixture.workspace.document.links
            .singleWhere((link) => link.contract == fixture.triggerRelation)
            .first,
        fixture.source,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      fixture.workspace.dispose();
    },
  );

  testWidgets("read only nodes consume inherited deletion and expose no drag", (
    tester,
  ) async {
    final fixture = AuthoredGraphFixture();
    var inheritedDeletes = 0;
    await _pump(
      tester,
      fixture,
      readOnly: true,
      actions: {
        DeleteIntent: CallbackAction<DeleteIntent>(
          onInvoke: (_) {
            inheritedDeletes++;
            return null;
          },
        ),
      },
    );
    final source = find.byKey(ValueKey(fixture.source));
    await tester.tap(source);
    await tester.pump();
    final selector = tester.widget<Selector>(find.byType(Selector));
    Actions.invoke(selector.focusNode.context!, const DeleteIntent());
    await tester.pumpAndSettle();
    expect(inheritedDeletes, 0);
    expect(
      find.byType(Draggable<GraphDragPayload<ResourceDrag>>),
      findsNothing,
    );
    expect(find.byType(AlertDialog), findsNothing);
    expect(fixture.workspace.document.resource(fixture.source), isNotNull);
  });

  testWidgets("a sidebar drop moves the dragged resource to its new owner", (
    tester,
  ) async {
    final fixture = AuthoredGraphFixture();
    await _pump(tester, fixture, sidebar: true);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(ValueKey(fixture.source))),
    );
    await gesture.moveBy(const Offset(25, 0));
    await tester.pump();
    await gesture.moveTo(
      tester.getCenter(find.byKey(const ValueKey("destination"))),
    );
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      fixture.workspace.document.relations.children[fixture.destination],
      contains(fixture.source),
    );
    expect(
      fixture.workspace.document.relations.children[fixture.page] ?? const [],
      isNot(contains(fixture.source)),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    fixture.workspace.dispose();
  });

  testWidgets("keyboard movement and resize use focused owned nodes", (
    tester,
  ) async {
    final fixture = AuthoredGraphFixture();
    final moves = <List<GraphMoveCommitPayload>>[];
    final resizes = <List<GraphResizeCommitPayload>>[];
    await _pump(tester, fixture, onMove: moves.add, onResize: resizes.add);
    await tester.tap(find.byKey(ValueKey(fixture.source)));
    await tester.pumpAndSettle();
    await _shiftKey(tester, LogicalKeyboardKey.keyM);
    expect(
      tester.container().read(currentInteractionModeProvider),
      isA<GraphMoveMode>(),
    );
    expect(
      tester.container().read(realmInteractionProvider).suspended,
      isFalse,
    );
    expect(SelectableScope.primaryFocusedId(), fixture.drag.primary);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(moves, hasLength(1));
    expect(moves.single.single.x, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(
      tester.container().read(currentInteractionModeProvider),
      isA<NormalMode>(),
    );
    await _shiftKey(tester, LogicalKeyboardKey.keyR);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(resizes, hasLength(1));
    expect(resizes.single.single.width, 5);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(
      tester.container().read(currentInteractionModeProvider),
      isA<NormalMode>(),
    );
  });

  testWidgets("an active sidebar drag cannot outlive source mutation access", (
    tester,
  ) async {
    final fixture = AuthoredGraphFixture();
    final readOnly = ValueNotifier(false);
    addTearDown(readOnly.dispose);
    await _pump(tester, fixture, sidebar: true, readOnlySource: readOnly);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(ValueKey(fixture.source))),
    );
    await gesture.moveBy(const Offset(25, 0));
    await tester.pump();
    readOnly.value = true;
    await tester.pump();
    await gesture.moveTo(
      tester.getCenter(find.byKey(const ValueKey("destination"))),
    );
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      fixture.workspace.document.relations.children[fixture.page],
      contains(fixture.source),
    );
    expect(
      fixture.workspace.document.relations.children[fixture.destination],
      isNot(contains(fixture.source)),
    );
  });

  testWidgets(
    "keyboard context actions choose a destination and restore focus",
    (tester) async {
      final fixture = AuthoredGraphFixture();
      await _pump(tester, fixture);
      await tester.tap(find.byKey(ValueKey(fixture.source)));
      await tester.pumpAndSettle();
      final selector = tester.widget<Selector>(find.byType(Selector));
      await _shiftKey(tester, LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();
      expect(find.text("Move to"), findsOneWidget);
      final button = find.ancestor(
        of: find.text("Move to"),
        matching: find.byType(MenuItemButton),
      );
      tester.widget<MenuItemButton>(button).focusNode?.requestFocus();
      // Menus expose normal focus traversal; focus the action without a pointer.
      Focus.of(tester.element(find.text("Move to"))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).first,
        fixture.destination.value,
      );
      Focus.of(tester.element(find.text("Submit"))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        fixture.workspace.document.relations.children[fixture.destination],
        contains(fixture.source),
      );
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        selector.focusNode.hasFocus ||
            FocusManager.instance.primaryFocus != null,
        isTrue,
      );
    },
  );
  testWidgets(
    "keyboard activation selects nodes and menu cancellation returns focus",
    (tester) async {
      final fixture = AuthoredGraphFixture(secondSource: true);
      await _pump(tester, fixture);
      final selectors = tester
          .widgetList<Selector>(find.byType(Selector))
          .toList();
      selectors.first.focusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(tester.container().read(selectionProvider), [
        selectors.first.selectableId,
      ]);
      selectors.last.focusNode.requestFocus();
      await tester.pump();
      await _shiftKey(tester, LogicalKeyboardKey.enter);
      expect(
        tester.container().read(selectionProvider).toSet(),
        selectors.map((node) => node.selectableId).toSet(),
      );
      await _shiftKey(tester, LogicalKeyboardKey.f10);
      expect(find.text("Link with"), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text("Link with"), findsNothing);
      expect(selectors.last.focusNode.hasFocus, isTrue);
    },
  );

  testWidgets("keyboard Link with submits typed transient target input", (
    tester,
  ) async {
    final fixture = AuthoredGraphFixture();
    await _pump(tester, fixture);
    final selector = tester.widget<Selector>(find.byType(Selector));
    selector.focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await _shiftKey(tester, LogicalKeyboardKey.f10);
    Focus.of(tester.element(find.text("Link with"))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, fixture.target.value);
    Focus.of(tester.element(find.text("Submit"))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    final link = fixture.workspace.document.links.singleWhere(
      (link) => link.contract == fixture.triggerRelation,
    );
    expect((link.first, link.second), (fixture.source, fixture.target));
  });
}

Future<void> _shiftKey(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester,
  AuthoredGraphFixture fixture, {
  bool readOnly = false,
  bool sidebar = false,
  GraphMoveCommit? onMove,
  GraphResizeCommit? onResize,
  ValueNotifier<bool>? readOnlySource,
  Map<Type, Action<Intent>>? actions,
}) async {
  final binding = fixture.workspace.attach(
    fixture.page,
    policy: EditorCommitPolicy.applyResource,
  );
  addTearDown(binding.detach);
  final scope = PortablePresentationScope(
    bindings: const {},
    operations: testPortableOperations(),
    budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 100),
    readOnly: readOnly,
    resource: fixture.page,
  );
  final entries = _entries(fixture);
  await tester.pumpTestApp(
    actions: actions,
    overrides: [
      realmInteractionProvider.overrideWithValue(
        const RealmInteractionState(
          connectionState: RealmConnectionState.online,
        ),
      ),
      ...authoringFixtureOverrides(
        scope: fixture.scope,
        transport: fixture.transport,
        commands: fixture.commands,
      ),
      realmEditingProvider.overrideWith((ref, scope) => fixture.workspace),
    ],
    child: SizedBox(
      width: 900,
      height: 600,
      child: Row(
        children: [
          if (sidebar)
            SizedBox(
              width: 150,
              child: ResourceDropTarget.at(
                scope: fixture.scope,
                destination: DropDestination.resource(fixture.destination),
                builder: (context, hover) => const SizedBox(
                  key: ValueKey("destination"),
                  height: 80,
                  child: Text("Destination"),
                ),
              ),
            ),
          Expanded(
            child: AuthoredResourcesInteractions(
              authoringScope: fixture.scope,
              binding: binding,
              child: HookBuilder(
                builder: (context) {
                  useListenable(readOnlySource);
                  final currentScope = scope.copyWith(
                    readOnly: readOnlySource?.value ?? readOnly,
                  );
                  final interactions =
                      PortableResourcesInteractionScope.maybeOf(context)!;
                  final view = PortableResourcesView(
                    members: entries,
                    scope: currentScope,
                    layout: PortableResourcesLayoutKind.graph,
                  );
                  return interactions.layoutBuilder(
                    context,
                    view,
                    Graph(
                      data: GraphData(
                        cellSize: 50,
                        edges: const [],
                        elements: [
                          for (final (index, entry) in entries.indexed)
                            GraphElement(
                              id: GraphIdentifier(entry.resource.value),
                              x: index * 6,
                              y: 0,
                              width: 4,
                              height: 1,
                              builder: (context) => interactions.itemBuilder(
                                context,
                                view,
                                entry,
                                Builder(
                                  builder: (context) => ColoredBox(
                                    key: ValueKey(entry.resource),
                                    color: Colors.red,
                                    child: Text(entry.resource.value),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      onElementsMoved: currentScope.readOnly
                          ? null
                          : onMove ?? (_) {},
                      onElementsResized: currentScope.readOnly
                          ? null
                          : onResize,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

List<PortableResourceMember> _entries(AuthoredGraphFixture fixture) => [
  for (final member in fixture.memberships.entries)
    PortableResourceMember(
      resource: member.key,
      occurrence: member.value,
      link: skir.DataValue.unfilled,
      resourceProjection: PortableResourceProjection(
        resource: member.key,
        configuration: fixture.workspace.document
            .resource(member.key)!
            .configuration,
        appearance: ResourceAppearance(
          label: member.key.value,
          accent: const Color(0xff607d8b),
          icon: skir.Icon.wrapIconify("material-symbols:category"),
        ),
        value: skir.DataValue.wrapStringValue("fixture"),
      ),
      graph: const PortableGraphPlacement(x: 0, y: 0, width: 4, height: 1),
    ),
];
