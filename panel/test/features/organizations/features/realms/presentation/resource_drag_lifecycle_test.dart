import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../support/authored_graph_fixture.dart";
import "../../../../../support/test_utils.dart";

void main() {
  testWidgets(
    "completed accepted operation cannot clear a later gesture hover",
    (tester) async {
      final fixture = AuthoredGraphFixture();
      final release = Completer<void>();
      var pending = false;
      final commands = _commands(
        fixture,
        resolve: (request) async {
          if (request.invocation.invocationId.value != "drop-preflight") {
            pending = true;
            await release.future;
            return skir.ResolveResourceOperationsResult.wrapResolved(
              skir.ResolvedResourceOperations(
                primaryOperation: null,
                operations: const [],
              ),
            );
          }
          return fixture.commands.resolveResourceOperations(request);
        },
      );
      await _pumpOperation(tester, fixture, commands: commands);
      final target = tester.getCenter(find.byKey(const ValueKey("operation")));
      final first = await _startResourceDrag(tester, pointer: 1);
      await first.moveTo(target);
      await tester.pumpAndSettle();
      await first.up();
      await tester.pump();
      expect(pending, isTrue);
      final next = await _startResourceDrag(tester, pointer: 2);
      await next.moveTo(target);
      await tester.pumpAndSettle();
      expect(find.text("accepted"), findsOneWidget);
      release.complete();
      await tester.pumpAndSettle();
      expect(find.text("accepted"), findsOneWidget);
      await next.cancel();
      await tester.pumpAndSettle();
      expect(
        fixture.workspace.document.relations.children[fixture.destination],
        isNot(contains(fixture.source)),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "late preflight for an old selection cannot accept a replacement snapshot",
    (tester) async {
      final fixture = AuthoredGraphFixture(secondSource: true);
      final generation = ValueNotifier(0);
      addTearDown(generation.dispose);
      final releaseOld = Completer<void>();
      final checked = <int>[];
      final commands = _commands(
        fixture,
        resolve: (request) async {
          checked.add(request.invocation.targets.length);
          if (request.invocation.targets.length == 2) {
            await releaseOld.future;
            return fixture.commands.resolveResourceOperations(request);
          }
          return skir.ResolveResourceOperationsResult.wrapResolved(
            skir.ResolvedResourceOperations(
              primaryOperation: null,
              operations: const [],
            ),
          );
        },
      );
      await _pumpOperation(
        tester,
        fixture,
        generation: generation,
        commands: commands,
      );
      final container = tester.container(of: find.byType(AuthoredGraphItem));
      container
          .read(selectionProvider.notifier)
          .selectAll(fixture.group.memberships.keys.toList());
      await tester.pump();
      final old = await _startResourceDrag(tester, pointer: 1);
      final oldPayload = tester
          .widget<GraphDrag>(find.byType(GraphDrag))
          .controller
          .value!
          .payload;
      final target = tester.getCenter(find.byKey(const ValueKey("operation")));
      await old.moveTo(target);
      await tester.pump();
      expect(checked, contains(2));
      container.read(selectionProvider.notifier).clear();
      await tester.pump();
      expect(
        (oldPayload.value as AuthoringResourceDragGroup).memberships,
        hasLength(2),
      );
      generation.value++;
      await tester.pump();
      await tester.pump();
      final next = await _startResourceDrag(tester, pointer: 2);
      await next.moveTo(target);
      await tester.pumpAndSettle();
      expect(checked, contains(1));
      expect(find.text("rejected"), findsOneWidget);
      releaseOld.complete();
      await tester.pumpAndSettle();
      expect(find.text("rejected"), findsOneWidget);
      expect(find.text("accepted"), findsNothing);
      await old.moveTo(const Offset(10, 10));
      await tester.pump();
      expect(find.text("rejected"), findsOneWidget);
      await old.up();
      await next.up();
      await tester.pumpAndSettle();
      expect(
        fixture.workspace.document.relations.children[fixture.destination],
        isNot(contains(fixture.source)),
      );
      expect(fixture.preparations, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "accepted resource operation survives pointer retirement while resolution is pending",
    (tester) async {
      final fixture = AuthoredGraphFixture();
      final release = Completer<void>();
      var entered = false;
      final commands = _commands(
        fixture,
        resolve: (request) async {
          if (request.invocation.invocationId.value != "drop-preflight") {
            entered = true;
            await release.future;
          }
          return fixture.commands.resolveResourceOperations(request);
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
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pump();
      expect(entered, isTrue);
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
    "removing source ProviderScope hides root feedback and retires surviving operation hover",
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
      expect(find.text("accepted"), findsOneWidget);
      visible.value = false;
      await tester.pump();
      await tester.pump();
      expect(offered.phase, GraphDragPhase.retired);
      expect(find.byKey(const ValueKey("resource")), findsNothing);
      expect(find.text("accepted"), findsNothing);
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
      expect(find.text("accepted"), findsOneWidget);
      await old.moveTo(const Offset(10, 10));
      await tester.pump();
      expect(find.text("accepted"), findsOneWidget);
      await old.moveTo(target);
      await tester.pump();
      await old.up();
      await tester.pump();
      expect(find.text("accepted"), findsOneWidget);
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
    for (final member in fixture.group.memberships.entries)
      PortableResourceMember(
        resource: member.key.resourceId,
        occurrence: member.value,
        link: skir.DataValue.unfilled,
        resourceProjection: PortableResourceProjection(
          resource: member.key.resourceId,
          configuration: fixture.workspace.document
              .resource(member.key.resourceId)!
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
          child: ResourceOperationDropTarget(
            scope: fixture.scope,
            operationLocalId: "moveToPage",
            suppliedFields: {
              "destination": skir.DataValue.wrapStringValue(
                fixture.destination.value,
              ),
            },
            canMutate: () => fixture.mutable,
            builder: (_, accepted, rejected) => ColoredBox(
              key: const ValueKey("operation"),
              color: Colors.green,
              child: Text(
                accepted
                    ? "accepted"
                    : rejected
                    ? "rejected"
                    : "neutral",
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

AuthoredResourceCommands _commands(
  AuthoredGraphFixture fixture, {
  required Future<skir.ResolveResourceOperationsResult> Function(
    skir.ResolveResourceOperationsRequest,
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
    resolveResourceOperations: resolve,
    prepareAuthoringAction: base.prepareAuthoringAction,
  );
}
