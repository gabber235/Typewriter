import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../support/authored_graph_fixture.dart";
import "../../../../../support/test_utils.dart";

void main() {
  testWidgets(
    "a drag resolves its candidates once and hovering costs no round trip",
    (tester) async {
      final fixture = AuthoredGraphFixture();
      await _pumpOperation(tester, fixture);
      final target = tester.getCenter(find.byKey(const ValueKey("operation")));
      final gesture = await _startResourceDrag(tester);
      await gesture.moveTo(target);
      await tester.pumpAndSettle();
      expect(find.text("accepted: Move here"), findsOneWidget);
      await gesture.moveTo(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text("neutral"), findsOneWidget);
      await gesture.moveTo(target);
      await tester.pumpAndSettle();
      expect(find.text("accepted: Move here"), findsOneWidget);
      expect(fixture.dropResolutions, hasLength(1));
      expect(fixture.preparations, isEmpty);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(fixture.dropResolutions, hasLength(1));
      expect(
        fixture.workspace.document.relations.children[fixture.destination],
        contains(fixture.source),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      fixture.workspace.dispose();
    },
  );

  testWidgets("a destination without offers rejects the drag", (tester) async {
    final fixture = AuthoredGraphFixture();
    await _pumpOperation(tester, fixture, destination: fixture.page);
    final gesture = await _startResourceDrag(tester);
    await gesture.moveTo(
      tester.getCenter(find.byKey(const ValueKey("operation"))),
    );
    await tester.pumpAndSettle();
    expect(find.text("rejected"), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(fixture.preparations, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    "accepted drop survives pointer retirement while candidates are pending",
    (tester) async {
      final fixture = AuthoredGraphFixture();
      final release = Completer<void>();
      final commands = _commands(
        fixture,
        resolve: (request) async {
          await release.future;
          return fixture.commands.resolveDropCandidates(request);
        },
      );
      await _pumpOperation(tester, fixture, commands: commands);
      final gesture = await _startResourceDrag(tester);
      final offered = tester
          .widget<GraphDrag>(find.byType(GraphDrag))
          .controller
          .value!
          .payload;
      await gesture.moveTo(
        tester.getCenter(find.byKey(const ValueKey("operation"))),
      );
      await tester.pump();
      expect(find.text("neutral"), findsOneWidget);
      await gesture.up();
      await tester.pump();
      expect(offered.phase, GraphDragPhase.retired);
      expect(
        fixture.workspace.document.relations.children[fixture.destination],
        isNot(contains(fixture.source)),
      );
      release.complete();
      await tester.pumpAndSettle();
      expect(
        fixture.workspace.document.relations.children[fixture.destination],
        contains(fixture.source),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      fixture.workspace.dispose();
    },
  );

  testWidgets(
    "a drop accepted while candidates load reaches the enclosing target when "
    "the inner target turns out to offer nothing",
    (tester) async {
      final fixture = AuthoredGraphFixture();
      final release = Completer<void>();
      final commands = _commands(
        fixture,
        resolve: (request) async {
          await release.future;
          return fixture.commands.resolveDropCandidates(request);
        },
      );
      await _pumpOperation(
        tester,
        fixture,
        commands: commands,
        destination: fixture.page,
        enclosing: fixture.destination,
      );
      final gesture = await _startResourceDrag(tester);
      await gesture.moveTo(
        tester.getCenter(find.byKey(const ValueKey("operation"))),
      );
      await tester.pump();
      expect(find.text("neutral"), findsOneWidget);
      await gesture.up();
      await tester.pump();
      release.complete();
      await tester.pumpAndSettle();
      expect(
        fixture.workspace.document.relations.children[fixture.destination],
        contains(fixture.source),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      fixture.workspace.dispose();
    },
  );

  testWidgets(
    "a target that can offer nothing refuses while candidates load, so the "
    "enclosing target receives the drag",
    (tester) async {
      final fixture = AuthoredGraphFixture();
      final release = Completer<void>();
      final commands = _commands(
        fixture,
        resolve: (request) async {
          await release.future;
          return fixture.commands.resolveDropCandidates(request);
        },
      );
      await _pumpOperation(
        tester,
        fixture,
        commands: commands,
        // A dragged resource is never its own destination.
        destination: fixture.source,
        enclosing: fixture.destination,
      );
      final gesture = await _startResourceDrag(tester);
      await gesture.moveTo(
        tester.getCenter(find.byKey(const ValueKey("operation"))),
      );
      await tester.pump();
      expect(find.text("rejected"), findsOneWidget);
      expect(find.text("enclosing neutral"), findsOneWidget);
      release.complete();
      await tester.pumpAndSettle();
      expect(find.text("enclosing accepted: Move here"), findsOneWidget);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        fixture.workspace.document.relations.children[fixture.destination],
        contains(fixture.source),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      fixture.workspace.dispose();
    },
  );

  testWidgets(
    "several offers open the drop chooser, and Escape cancels the drop",
    (tester) async {
      final fixture = AuthoredGraphFixture();
      final commands = _commands(
        fixture,
        resolve: (request) async =>
            skir.ResolveDropCandidatesResult.wrapResolved([
              for (final operation in ["linkWith", "moveToOwner"])
                skir.DropCandidates(
                  operation: fixtureOperationId(operation),
                  destinations: [fixture.destination],
                  complete: true,
                ),
            ]),
      );
      await _pumpOperation(tester, fixture, commands: commands);
      final target = tester.getCenter(find.byKey(const ValueKey("operation")));
      var gesture = await _startResourceDrag(tester);
      await gesture.moveTo(target);
      await tester.pumpAndSettle();
      expect(find.text("accepted: 2 options"), findsOneWidget);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.byType(DropChooser), findsOneWidget);
      final labels = tester
          .widgetList<MenuItemButton>(
            find.descendant(
              of: find.byType(DropChooser),
              matching: find.byType(MenuItemButton),
            ),
          )
          .map((button) => (button.child! as Text).data)
          .toList();
      expect(labels, ["Move to", "Link with"]);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(DropChooser), findsNothing);
      expect(fixture.preparations, isEmpty);

      gesture = await _startResourceDrag(tester, pointer: 2);
      await gesture.moveTo(target);
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(DropChooser),
          matching: find.text("Move to"),
        ),
      );
      await tester.pumpAndSettle();
      expect(fixture.preparations.single.capability.value, "moveToOwner");
      expect(
        fixture.workspace.document.relations.children[fixture.destination],
        contains(fixture.source),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      fixture.workspace.dispose();
    },
  );

  testWidgets(
    "removing source ProviderScope hides root feedback and retires the hover",
    (tester) async {
      final fixture = AuthoredGraphFixture();
      final visible = ValueNotifier(true);
      addTearDown(visible.dispose);
      await _pumpOperation(tester, fixture, visible: visible);
      final gesture = await _startResourceDrag(tester);
      final offered = tester
          .widget<GraphDrag>(find.byType(GraphDrag))
          .controller
          .value!
          .payload;
      await gesture.moveTo(
        tester.getCenter(find.byKey(const ValueKey("operation"))),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey("resource")), findsNWidgets(2));
      expect(find.text("accepted: Move here"), findsOneWidget);
      visible.value = false;
      await tester.pump();
      await tester.pump();
      expect(offered.phase, GraphDragPhase.retired);
      expect(find.byKey(const ValueKey("resource")), findsNothing);
      expect(find.text("accepted: Move here"), findsNothing);
      expect(find.text("rejected"), findsNothing);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        fixture.workspace.document.relations.children[fixture.destination],
        isNot(contains(fixture.source)),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "old resource avatar leave and drop preserve the replacement hover",
    (tester) async {
      final fixture = AuthoredGraphFixture();
      final generation = ValueNotifier(0);
      addTearDown(generation.dispose);
      await _pumpOperation(tester, fixture, generation: generation);
      final old = await _startResourceDrag(tester, pointer: 1);
      final target = tester.getCenter(find.byKey(const ValueKey("operation")));
      await old.moveTo(target);
      await tester.pumpAndSettle();
      generation.value++;
      await tester.pump();
      await tester.pump();
      final next = await _startResourceDrag(tester, pointer: 2);
      await next.moveTo(target);
      await tester.pumpAndSettle();
      expect(find.text("accepted: Move here"), findsOneWidget);
      await old.moveTo(const Offset(10, 10));
      await tester.pump();
      expect(find.text("accepted: Move here"), findsOneWidget);
      await old.moveTo(target);
      await tester.pump();
      await old.up();
      await tester.pump();
      expect(find.text("accepted: Move here"), findsOneWidget);
      expect(
        fixture.workspace.document.relations.children[fixture.destination],
        isNot(contains(fixture.source)),
      );
      await next.up();
      await tester.pumpAndSettle();
      expect(
        fixture.workspace.document.relations.children[fixture.destination],
        contains(fixture.source),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      fixture.workspace.dispose();
    },
  );
}

Future<TestGesture> _startResourceDrag(
  WidgetTester tester, {
  int pointer = 1,
}) async {
  final source = find.descendant(
    of: find.byType(Graph),
    matching: find.byKey(const ValueKey("resource")),
  );
  final gesture = await tester.startGesture(
    tester.getCenter(source),
    pointer: pointer,
  );
  await gesture.moveBy(const Offset(25, 0));
  await tester.pump();
  return gesture;
}

Future<void> _pumpOperation(
  WidgetTester tester,
  AuthoredGraphFixture fixture, {
  AuthoredResourceCommands? commands,
  ValueNotifier<bool>? visible,
  ValueNotifier<int>? generation,
  skir.ResourceId? destination,
  skir.ResourceId? enclosing,
}) async {
  final binding = fixture.workspace.attach(
    fixture.page,
    policy: EditorCommitPolicy.applyResource,
  );
  addTearDown(binding.detach);
  final pageScope = PortablePresentationScope(
    bindings: const {},
    operations: testPortableOperations(),
    budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 100),
    resource: fixture.page,
  );
  final entries = [
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
            label: "Source",
            accent: const Color(0xff607d8b),
            icon: skir.Icon.wrapIconify("material-symbols:category"),
          ),
          value: skir.DataValue.wrapStringValue("fixture"),
        ),
        graph: const PortableGraphPlacement(x: 0, y: 0, width: 4, height: 1),
      ),
  ];
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
        commands: commands ?? fixture.commands,
      ),
      realmEditingProvider.overrideWith((ref, scope) => fixture.workspace),
    ],
    child: Row(
      children: [
        Expanded(
          child: HookBuilder(
            builder: (context) {
              useListenable(visible);
              useListenable(generation);
              if (!(visible?.value ?? true)) return const SizedBox.shrink();
              return ProviderScope(
                key: ValueKey(generation?.value ?? 0),
                child: AuthoredResourcesInteractions(
                  authoringScope: fixture.scope,
                  binding: binding,
                  child: Builder(
                    builder: (context) {
                      final interactions =
                          PortableResourcesInteractionScope.maybeOf(context)!;
                      final view = PortableResourcesView(
                        members: entries,
                        scope: pageScope,
                        layout: PortableResourcesLayoutKind.graph,
                      );
                      return interactions.layoutBuilder(
                        context,
                        view,
                        SizedBox(
                          height: 300,
                          child: Graph(
                            data: GraphData(
                              cellSize: 50,
                              edges: const [],
                              elements: [
                                GraphElement(
                                  id: GraphIdentifier(fixture.source.value),
                                  x: 0,
                                  y: 0,
                                  width: 4,
                                  height: 1,
                                  builder: (context) =>
                                      interactions.itemBuilder(
                                        context,
                                        view,
                                        entries.first,
                                        const ColoredBox(
                                          key: ValueKey("resource"),
                                          color: Colors.blue,
                                          child: Text("Source"),
                                        ),
                                      ),
                                ),
                              ],
                            ),
                            onElementsMoved: (_) {},
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(
          width: 180,
          height: 100,
          child: _enclosedBy(
            fixture,
            enclosing,
            ResourceDropTarget.at(
              scope: fixture.scope,
              destination: DropDestination.resource(
                destination ?? fixture.destination,
              ),
              canMutate: () => fixture.mutable,
              builder: (_, hover) => ColoredBox(
                key: const ValueKey("operation"),
                color: Colors.green,
                child: Text(_hoverText(hover)),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

String _hoverText(ResourceDropHover hover) => hover.accepted
    ? "accepted: ${hover.hint}"
    : hover.rejected
    ? "rejected"
    : "neutral";

/// Places [target] inside a padded drop target for [enclosing], when given.
Widget _enclosedBy(
  AuthoredGraphFixture fixture,
  skir.ResourceId? enclosing,
  Widget target,
) => enclosing == null
    ? target
    : ResourceDropTarget.at(
        scope: fixture.scope,
        destination: DropDestination.resource(enclosing),
        canMutate: () => fixture.mutable,
        builder: (_, hover) => Column(
          children: [
            Text("enclosing ${_hoverText(hover)}"),
            Expanded(child: target),
          ],
        ),
      );

AuthoredResourceCommands _commands(
  AuthoredGraphFixture fixture, {
  required Future<skir.ResolveDropCandidatesResult> Function(
    skir.ResolveDropCandidatesRequest,
  )
  resolve,
}) {
  final base = fixture.commands;
  return AuthoredResourceCommands(
    previewTypeArguments: base.previewTypeArguments,
    prepareTypeArguments: base.prepareTypeArguments,
    prepareValue: base.prepareValue,
    prepareStep: base.prepareStep,
    invokeCommand: base.invokeCommand,
    watchSearch: base.watchSearch,
    search: base.search,
    reload: base.reload,
    resolveResourceOperations: base.resolveResourceOperations,
    resolveDropCandidates: (request) {
      fixture.dropResolutions.add(request);
      return resolve(request);
    },
    prepareAuthoringAction: base.prepareAuthoringAction,
  );
}
