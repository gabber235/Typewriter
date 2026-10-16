import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../support/test_utils.dart";

void main() {
  test("normal collection examples start without authored errors", () {
    for (final example in CollectionEditorExample.values) {
      if (example == CollectionEditorExample.unfinishedSteps) continue;
      final scenario = _scenario(example);
      expect(
        scenario.host.document.diagnostics
            .where(
              (diagnostic) =>
                  diagnostic.severity == skir.DiagnosticSeverity.error,
            )
            .map((diagnostic) => diagnostic.message),
        isEmpty,
        reason: example.name,
      );
    }
  });

  testWidgets("omitted scalar children edit their stable source items inline", (
    tester,
  ) async {
    final scenario = _scenario();
    await _pump(tester, scenario);
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.byTooltip("Expand"), findsNothing);
    await tester.enterText(find.byType(TextFormField).first, "Landing");
    await tester.pumpAndSettle();
    expect(
      scenario.value.authoredItems!.first.id,
      CollectionEditorScenario.first,
    );
    expect(scenario.value.authoredItems!.first.value.authoredString, "Landing");
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    "map key edits and width changes preserve row and editor identity",
    (tester) async {
      final scenario = _scenario(CollectionEditorExample.scalarMap);
      await _pump(tester, scenario, width: 640);
      final original = _editable(tester, 0);
      await tester.enterText(find.byType(TextFormField).first, "opening");
      await tester.pumpAndSettle();
      final rows =
          (scenario.value.authoredPayload as skir.DataValue_mapValueWrapper)
              .value
              .rows;
      expect(rows.first.id, CollectionEditorScenario.first);
      expect(rows.first.key.authoredString, "opening");
      expect(rows.first.value.authoredString, "Arrival");
      await _pump(tester, scenario, width: 320);
      expect(_editable(tester, 0).controller, same(original.controller));
      expect(_editable(tester, 0).focusNode, same(original.focusNode));
      expect(_editable(tester, 0).focusNode.hasFocus, isTrue);
      expect(_editable(tester, 0).controller.text, "opening");
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "authored titles refresh without collapsing or replacing inputs",
    (tester) async {
      final scenario = _scenario(CollectionEditorExample.authoredSteps);
      await _pump(tester, scenario);
      await tester.tap(find.text("Arrival"));
      await tester.pumpAndSettle();
      final original = _editable(tester, 0);
      await tester.enterText(find.byType(TextFormField).first, "Landing");
      await tester.pumpAndSettle();
      expect(find.text("Landing"), findsNWidgets(2));
      expect(_editable(tester, 0).controller, same(original.controller));
      expect(_editable(tester, 0).focusNode.hasFocus, isTrue);
      expect(find.byType(TextFormField), findsNWidgets(2));
      await _pump(tester, scenario, width: 320);
      expect(_editable(tester, 0).controller, same(original.controller));
      expect(_editable(tester, 0).focusNode.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("a collection disclosure preserves an invalid numeric draft", (
    tester,
  ) async {
    final scenario = _scenario(CollectionEditorExample.authoredSteps);
    await _pump(tester, scenario);
    await tester.tap(find.text("Arrival").first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), "-");
    await tester.pumpAndSettle();
    expect(_editable(tester, 1).controller.text, "-");
    await tester.tap(find.text("Arrival").first);
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNothing);
    await tester.tap(find.text("Arrival").first);
    await tester.pumpAndSettle();
    expect(_editable(tester, 1).controller.text, "-");
    expect(
      scenario.value.authoredItems!.first.value
          .authoredField("amount")!
          .authoredInteger,
      BigInt.one,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    "fallback disclosure follows source identity through keyboard movement",
    (tester) async {
      final scenario = _scenario(CollectionEditorExample.fallbackSteps);
      await _pump(tester, scenario);
      expect(find.text("Item 1"), findsOneWidget);
      expect(find.text("Item 2"), findsOneWidget);
      await tester.tap(find.text("Item 1"));
      await tester.pumpAndSettle();
      final original = _editable(tester, 0).controller;
      await tester.tap(find.byTooltip("Reorder item 1"));
      final handleFocus = FocusManager.instance.primaryFocus;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pumpAndSettle();
      expect(scenario.value.authoredItems!.map((item) => item.id), [
        CollectionEditorScenario.second,
        CollectionEditorScenario.first,
      ]);
      expect(_editable(tester, 0).controller, same(original));
      expect(FocusManager.instance.primaryFocus, same(handleFocus));
      expect(
        tester.getTopLeft(find.byType(TextFormField).first).dy,
        greaterThan(tester.getTopLeft(find.text("Item 2")).dy),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "pointer dragging moves the source item through the real sequence",
    (tester) async {
      final scenario = _scenario();
      await _pump(tester, scenario);
      final first = find.byTooltip("Reorder item 1");
      final last = find.byTooltip("Reorder item 3");
      final destination = tester.getCenter(last) + const Offset(0, 80);
      final gesture = await tester.startGesture(tester.getCenter(first));
      await gesture.moveBy(const Offset(0, 24));
      await tester.pumpAndSettle();
      await gesture.moveTo(destination);
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        scenario.value.authoredItems!.last.id,
        CollectionEditorScenario.first,
      );
      expect(scenario.value.authoredItems!.map((item) => item.id).toSet(), {
        CollectionEditorScenario.first,
        CollectionEditorScenario.second,
        CollectionEditorScenario.third,
      });
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "pointer reordering retains an expanded row's invalid numeric draft",
    (tester) async {
      final scenario = _scenario(CollectionEditorExample.authoredSteps);
      await _pump(tester, scenario);
      await tester.tap(find.text("Arrival").first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(1), "-");
      await tester.pumpAndSettle();
      final originalEditor = _editable(tester, 1);
      final original = originalEditor.controller;
      final originalFocus = originalEditor.focusNode;
      final first = find.byTooltip("Reorder item 1");
      final last = find.byTooltip("Reorder item 2");
      final handleFocus = _reorderFocus(tester, first);
      final destination = tester.getCenter(last) + const Offset(0, 80);
      final gesture = await tester.startGesture(tester.getCenter(first));
      await gesture.moveBy(const Offset(0, 24));
      await tester.pumpAndSettle();
      await gesture.moveTo(destination);
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        scenario.value.authoredItems!.last.id,
        CollectionEditorScenario.first,
      );
      expect(originalFocus.hasFocus, isFalse);
      expect(FocusManager.instance.primaryFocus, same(handleFocus));
      expect(_reorderFocus(tester, last), same(handleFocus));
      expect(_editable(tester, 1).controller, same(original));
      expect(_editable(tester, 1).controller.text, "-");
      expect(
        scenario.value.authoredItems!.last.value
            .authoredField("amount")!
            .authoredInteger,
        BigInt.one,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("default map children remove their containing source row", (
    tester,
  ) async {
    final scenario = _scenario(CollectionEditorExample.scalarMap);
    await _pump(tester, scenario);
    await tester.tap(find.byTooltip("Remove row").first);
    await tester.pumpAndSettle();
    final rows =
        (scenario.value.authoredPayload as skir.DataValue_mapValueWrapper)
            .value
            .rows;
    expect(rows, hasLength(1));
    expect(rows.single.id, CollectionEditorScenario.second);
    expect(rows.single.key.authoredString, "discovery");
    expect(rows.single.value.authoredString, "Discovery");
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    "direct link Clear changes its relation and preserves sibling identity",
    (tester) async {
      final scenario = _scenario(CollectionEditorExample.directLinks);
      final before = scenario.value.authoredItems!.toList();
      final unrelated = scenario.workspace.document
          .resource(compiledInheritanceBookId)!
          .authoredField("tags");
      final relations = scenario.workspace.document.links.length;
      await _pump(tester, scenario);
      expect(find.byTooltip("Clear link"), findsNWidgets(2));
      expect(find.byTooltip("Remove item"), findsNothing);
      await tester.tap(find.byTooltip("Clear link").first);
      await tester.pumpAndSettle();
      expect(scenario.value.authoredItems, hasLength(1));
      expect(scenario.value.authoredItems!.single.id, before.last.id);
      expect(scenario.workspace.document.links, hasLength(relations - 1));
      expect(
        scenario.workspace.document
            .resource(compiledInheritanceBookId)!
            .authoredField("tags"),
        unrelated,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("read only collections remain inspectable and cannot mutate", (
    tester,
  ) async {
    final scenario = _scenario(CollectionEditorExample.authoredSteps);
    final before = scenario.value;
    await _pump(tester, scenario, readOnly: true);
    await tester.tap(find.text("Arrival"));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(_editable(tester, 0).readOnly, isTrue);
    for (final button in tester.widgetList<IconButton>(
      find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            (widget.tooltip == "Remove item" || widget.tooltip == "Add item"),
      ),
    )) {
      expect(button.onPressed, isNull);
    }
    expect(scenario.value, before);
    expect(tester.takeException(), isNull);
  });

  testWidgets("cancelling authored removal leaves the actual draft untouched", (
    tester,
  ) async {
    final scenario = CollectionEditorScenario(
      example: CollectionEditorExample.authoredSteps,
      confirmRemoval: true,
    );
    addTearDown(scenario.dispose);
    await _pump(tester, scenario);
    final before = scenario.value;
    await tester.tap(find.byTooltip("Remove step").first);
    await tester.pumpAndSettle();
    expect(find.text("Remove this step?"), findsOneWidget);
    await tester.tap(find.text("Cancel"));
    await tester.pumpAndSettle();
    expect(scenario.value, before);
    expect(scenario.workspace.hasPendingWork, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets("accepted delayed removal focuses the surviving row control", (
    tester,
  ) async {
    final scenario = _scenario();
    final gate = Completer<bool>();
    final host = _DelayedRemovalHost(scenario.host, gate);
    addTearDown(host.dispose);
    await _pump(tester, scenario, host: host);
    final remove = find.byTooltip("Remove item").first;
    await _activateWithKeyboard(tester, remove);
    await tester.pump();
    expect(scenario.value.authoredItems, hasLength(3));
    gate.complete(true);
    await tester.pumpAndSettle();
    expect(
      scenario.value.authoredItems!.first.id,
      CollectionEditorScenario.second,
    );
    final surviving = _button(tester, find.byTooltip("Remove item").first);
    expect(surviving.focusNode!.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets("removing the last row recovers to the preceding source row", (
    tester,
  ) async {
    final scenario = _scenario();
    await _pump(tester, scenario);
    await _activateWithKeyboard(tester, find.byTooltip("Remove item").last);
    await tester.pumpAndSettle();
    expect(
      scenario.value.authoredItems!.last.id,
      CollectionEditorScenario.second,
    );
    final remaining = _button(tester, find.byTooltip("Remove item").last);
    expect(remaining.focusNode!.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets("removing the only row recovers to collection Add", (
    tester,
  ) async {
    final scenario = _scenario();
    _keepRows(scenario, 1);
    await _pump(tester, scenario);
    await _activateWithKeyboard(tester, find.byTooltip("Remove item"));
    await tester.pumpAndSettle();
    expect(scenario.value.authoredItems, isEmpty);
    expect(
      _button(tester, find.byTooltip("Add item")).focusNode!.hasFocus,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets("rejected delayed removal retains the initiating control", (
    tester,
  ) async {
    final scenario = _scenario();
    final gate = Completer<bool>();
    final host = _DelayedRemovalHost(scenario.host, gate);
    addTearDown(host.dispose);
    await _pump(tester, scenario, host: host);
    final remove = find.byTooltip("Remove item").first;
    await _activateWithKeyboard(tester, remove);
    final origin = FocusManager.instance.primaryFocus;
    gate.complete(false);
    await tester.pumpAndSettle();
    expect(scenario.value.authoredItems, hasLength(3));
    expect(FocusManager.instance.primaryFocus, same(origin));
    expect(
      _button(tester, find.byTooltip("Add item")).focusNode!.hasFocus,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    "retired removal plus source disappearance never recovers focus",
    (tester) async {
      final scenario = _scenario();
      final gate = Completer<bool>();
      final host = _DelayedRemovalHost(scenario.host, gate);
      addTearDown(host.dispose);
      await _pump(tester, scenario, host: host);
      await _activateWithKeyboard(tester, find.byTooltip("Remove item").first);
      final renderer = tester.widget<PortablePresentationNodeRenderer>(
        find.byType(PortablePresentationNodeRenderer).first,
      );
      expect(
        renderer.scope.operations.value.outcomes.values.any(
          (outcome) => outcome.pending,
        ),
        isTrue,
      );
      renderer.scope.operations.retirePending();
      expect(renderer.scope.operations.value.outcomes, isEmpty);
      final remaining = scenario.value.authoredItems!.skip(1).toList();
      scenario.binding
          .edit(
            label: "External row disappearance",
            apply: (edit) => edit.set(
              skir.ValueLocation(
                resource: CollectionEditorScenario.resource,
                path: CollectionEditorScenario.entriesPath,
              ),
              skir.DataValue.createNamed(
                actualType: scenario.value.authoredActualType!,
                payload: skir.DataValue.createListValue(items: remaining),
              ),
            ),
          )
          .requireAccepted();
      await tester.pump();
      await tester.pump();
      final frameworkFallback = FocusManager.instance.primaryFocus;
      gate.complete(false);
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, same(frameworkFallback));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "cancelling a nested collection header removal preserves both owners",
    (tester) async {
      final scenario = CollectionEditorScenario(
        example: CollectionEditorExample.nestedLists,
        confirmRemoval: true,
      );
      addTearDown(scenario.dispose);
      await _pump(tester, scenario);
      final before = scenario.value;
      await tester.tap(find.byTooltip("Remove step").first);
      await tester.pumpAndSettle();
      expect(find.text("Remove this step?"), findsOneWidget);
      await tester.tap(find.text("Cancel"));
      await tester.pumpAndSettle();
      expect(scenario.value, before);
      expect(scenario.workspace.hasPendingWork, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "a disposed collection cannot recover focus after delayed removal",
    (tester) async {
      final scenario = _scenario();
      final gate = Completer<bool>();
      final host = _DelayedRemovalHost(scenario.host, gate);
      addTearDown(host.dispose);
      final nextPageFocus = FocusNode();
      addTearDown(nextPageFocus.dispose);
      await _pump(tester, scenario, host: host);
      await _activateWithKeyboard(tester, find.byTooltip("Remove item").first);
      await tester.pumpTestApp(
        child: Scaffold(body: TextField(focusNode: nextPageFocus)),
      );
      nextPageFocus.requestFocus();
      await tester.pump();
      gate.complete(true);
      await tester.pumpAndSettle();
      expect(nextPageFocus.hasFocus, isTrue);
      expect(scenario.value.authoredItems, hasLength(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("focus moving within the pending row cancels removal recovery", (
    tester,
  ) async {
    final scenario = _scenario(CollectionEditorExample.authoredSteps);
    final gate = Completer<bool>();
    final settlement = Completer<void>();
    final host = _DelayedRemovalHost(
      scenario.host,
      gate,
      settlement: settlement,
    );
    addTearDown(host.dispose);
    await _pump(tester, scenario, host: host);
    await tester.tap(find.text("Arrival"));
    await tester.pumpAndSettle();
    await _activateWithKeyboard(tester, find.byTooltip("Remove item").first);
    await tester.pump();
    final changedFocus = _editable(tester, 0).focusNode..requestFocus();
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, same(changedFocus));
    gate.complete(true);
    expect(
      await host.sourceResult.future,
      isA<PortablePresentationWriteApplied>(),
    );
    await tester.pump();
    await tester.pump();
    expect(scenario.value.authoredItems, hasLength(1));
    final frameworkFallback = FocusManager.instance.primaryFocus;
    settlement.complete();
    await tester.pumpAndSettle();
    expect(
      scenario.value.authoredItems!.first.id,
      CollectionEditorScenario.second,
    );
    expect(FocusManager.instance.primaryFocus, same(frameworkFallback));
    expect(tester.takeException(), isNull);
  });
}

CollectionEditorScenario _scenario([
  CollectionEditorExample example = CollectionEditorExample.textList,
]) {
  final scenario = CollectionEditorScenario(example: example);
  addTearDown(scenario.dispose);
  return scenario;
}

void _keepRows(CollectionEditorScenario scenario, int count) {
  scenario.binding
      .edit(
        label: "Keep selected source rows",
        apply: (edit) => edit.set(
          skir.ValueLocation(
            resource: CollectionEditorScenario.resource,
            path: CollectionEditorScenario.entriesPath,
          ),
          skir.DataValue.createNamed(
            actualType: scenario.value.authoredActualType!,
            payload: skir.DataValue.createListValue(
              items: scenario.value.authoredItems!.take(count),
            ),
          ),
        ),
      )
      .requireAccepted();
}

Future<void> _pump(
  WidgetTester tester,
  CollectionEditorScenario scenario, {
  double width = 640,
  bool readOnly = false,
  PortablePresentationHost? host,
}) async {
  await tester.pumpTestApp(
    child: Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          width: width,
          child: CollectionEditorScenarioView(
            scenario: scenario,
            readOnly: readOnly,
            host: host,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

EditableText _editable(WidgetTester tester, int index) =>
    tester.widget<EditableText>(find.byType(EditableText).at(index));

IconButton _button(WidgetTester tester, Finder tooltip) =>
    tester.widget<IconButton>(
      find.ancestor(of: tooltip, matching: find.byType(IconButton)).first,
    );

FocusNode? _reorderFocus(WidgetTester tester, Finder tooltip) => tester
    .widget<FocusableActionDetector>(
      find
          .ancestor(of: tooltip, matching: find.byType(FocusableActionDetector))
          .first,
    )
    .focusNode;

Future<void> _activateWithKeyboard(WidgetTester tester, Finder finder) async {
  final target = _button(tester, finder).focusNode!;
  for (var step = 0; step < 30 && !target.hasFocus; step++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
  expect(target.hasFocus, isTrue);
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pump();
}

/// Delays admission at the host boundary, then uses the real mutation host.
final class _DelayedRemovalHost extends ChangeNotifier
    implements PortablePresentationHost, PortableCollectionMutationHost {
  _DelayedRemovalHost(this.source, this.admission, {this.settlement});
  final AuthoredPresentationHost source;
  final Completer<bool> admission;
  final Completer<void>? settlement;
  final sourceResult = Completer<PortablePresentationWriteResult>();
  @override
  PortablePresentationDocument get document => source.document;
  @override
  bool get enabled => source.enabled;
  @override
  bool get readOnly => source.readOnly;
  @override
  PortablePresentationCapabilities get capabilities => source.capabilities;
  @override
  EditControl? commitControl(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => source.commitControl(reference, context: context);
  @override
  skir.DataValue? read(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => source.read(reference, context: context);
  @override
  skir.ValueLocation? location(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => source.location(reference, context: context);
  @override
  skir.TypeUse? expectedType(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => source.expectedType(reference, context: context);
  @override
  Future<PortablePresentationWriteResult> write(
    skir.BindingRef reference,
    skir.DataValue value, {
    required PortableInvocationContext context,
  }) => source.write(reference, value, context: context);
  @override
  Future<PortablePresentationWriteResult> addCollectionItem(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => source.addCollectionItem(reference, context: context);
  @override
  Future<PortablePresentationWriteResult> addMapRow(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => source.addMapRow(reference, context: context);
  @override
  Future<PortablePresentationWriteResult> execute(
    skir.EditorAction action, {
    required PortableInvocationContext context,
  }) async {
    if (action case skir.EditorAction_localWrapper(
      value: skir.LocalEditorAction_removeListItemWrapper(),
    )) {
      if (!await admission.future) {
        return PortablePresentationWriteRejected([
          PortablePresentationDiagnostic(
            code: "fixture_rejected",
            message: "Removal rejected",
            severity: skir.DiagnosticSeverity.error,
          ),
        ]);
      }
    }
    final result = await source.execute(action, context: context);
    if (!sourceResult.isCompleted) sourceResult.complete(result);
    if (settlement case final pending?) await pending.future;
    return result;
  }
}
