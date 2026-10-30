import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("preview diagnostics leave source anchors and outcomes intact", (
    tester,
  ) async {
    final operations = PortableOperationResults();
    final sourceTree = PortableDiagnosticTree();
    addTearDown(operations.dispose);
    addTearDown(sourceTree.dispose);
    final sourceDiagnostic = invalidValueDiagnostic([
      _title,
    ], message: "Resource finding");
    final operationDiagnostic = invalidValueDiagnostic([
      _title,
    ], message: "Rejected edit");
    final key = PortableOperationKey.write(_title);
    await operations.run(
      key: key,
      input: PortableDiagnosticObservation(
        target: _title,
        value: skir.DataValue.wrapStringValue("editor value"),
      ),
      operation: () =>
          PortablePresentationWriteResult.rejected([operationDiagnostic]),
    );
    await tester.showComponent(
      PortableDiagnosticScope(
        tree: sourceTree,
        placement: const PortableDiagnosticPlacement(),
        child: PortableDiagnosticPreview(
          operations: operations,
          child: PortableDiagnosticSource(
            diagnostics: [sourceDiagnostic],
            diagnosticFallback: PortableDiagnosticFallback.resource,
            observations: [
              PortableDiagnosticObservation(
                target: _title,
                value: skir.DataValue.wrapStringValue("preview value"),
              ),
            ],
            child: PortableDiagnosticAnchor(
              node: diagnosticControl(_title),
              builder: (context, summary, owner) => Column(
                children: [
                  for (final diagnostic in summary.direct)
                    Text(diagnostic.message),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(sourceDiagnostic.message), findsOneWidget);
    expect(find.text(operationDiagnostic.message), findsOneWidget);
    expect(sourceTree.snapshot.nodes, isEmpty);
    expect(operations.value.outcomes.keys, [key]);
    final later = invalidValueDiagnostic([
      _title,
    ], message: "Updated rejection");
    await operations.run(
      key: key,
      operation: () => PortablePresentationWriteResult.rejected([later]),
    );
    await tester.pumpAndSettle();
    expect(find.text(later.message), findsOneWidget);
    expect(find.text(operationDiagnostic.message), findsNothing);
    await tester.showComponent(const SizedBox());
    await tester.pumpAndSettle();
    expect(sourceTree.snapshot.nodes, isEmpty);
    expect(operations.value.outcomes.values.single.diagnostics, [later]);
    operations.reportStatus("Still owned by the editor");
    expect(operations.value.outcomes, hasLength(2));
  });

  for (final entry in ["renderer", "node", "search"]) {
    for (final fallback in PortableDiagnosticFallback.values) {
      testWidgets("$entry preserves $fallback ownership for absent fields", (
        tester,
      ) async {
        final diagnostic = invalidValueDiagnostic([_count]);
        final host = DiagnosedTextHost(
          diagnostics: [diagnostic],
          diagnosticFallback: fallback,
        );
        final operations = PortableOperationResults();
        addTearDown(host.dispose);
        addTearDown(operations.dispose);
        final document = host.document;
        final scope = PortablePresentationScope(
          bindings: host.rootInvocation.bindings,
          budget: document.budget,
          operations: operations,
          host: host,
          role: skir.PresentationRole.inspector,
          catalog: document.catalog,
        );
        final search =
            (skir.SearchControl.mutable()
                  ..control =
                      (skir.BoundControl.mutable()
                            ..binding = skir.BindingRef(
                              bindingId: _binding,
                              path: editorRootPath,
                            ))
                          .toFrozen()
                  ..provider = skir.SearchProvider.createStaticValues(
                    values: skir.ExpressionNode.wrapLiteral(
                      skir.DataValue.createListValue(items: const []),
                    ),
                    result: skir.SearchResultMapping.defaultInstance,
                    selectors: const [],
                  ))
                .toFrozen();
        await tester.showComponent(
          Material(
            child: switch (entry) {
              "node" => PortablePresentationNodeRenderer(
                node: document.root,
                scope: scope,
              ),
              "search" => PortableSearchInput(control: search, scope: scope),
              _ => PortablePresentationRenderer(host: host),
            },
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(diagnostic.message),
          fallback == PortableDiagnosticFallback.presentation
              ? findsOneWidget
              : findsNothing,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    "resource validation cannot suppress an unmatched operation rejection",
    (tester) async {
      final diagnostic = invalidValueDiagnostic([_count]);
      final host = DiagnosedTextHost(
        diagnostics: [diagnostic],
        diagnosticFallback: PortableDiagnosticFallback.resource,
        response: Future.value(
          PortablePresentationWriteResult.rejected([diagnostic]),
        ),
      );
      final panel = await tester.showRenderer(host);
      expect(find.text(diagnostic.message), findsNothing);
      await panel.fieldAt(0).type("rejected draft");
      expect(host.requests, 1);
      expect(find.text(diagnostic.message), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "duplicated controls keep parser feedback with the edited draft",
    (tester) async {
      var current = skir.DataValue.wrapInteger("3");
      var writes = 0;
      final reference = skir.BindingRef(
        bindingId: _binding,
        path: editorRootPath,
      );
      final control = skir.BoundControl(
        binding: reference,
        label: null,
        description: null,
        prefix: null,
        semanticLabel: null,
      );
      final root = skir.PresentationNode(
        nodeId: "duplicates",
        properties: skir.PresentationProperties.defaultInstance,
        header: null,
        element: skir.PresentationElement.wrapChildren(
          skir.ChildrenElement.createColumn(
            children: [
              for (final id in ["first", "second"])
                skir.AxisChild.wrapFixed(
                  skir.PresentationNode(
                    nodeId: id,
                    properties: skir.PresentationProperties.defaultInstance,
                    header: null,
                    element: skir.PresentationElement.wrapNumericInput(
                      (skir.NumericControl.mutable()..control = control)
                          .toFrozen(),
                    ),
                  ),
                ),
            ],
            layout: skir.AxisChildrenLayout(
              clipOverflow: false,

              spacing: 12,
              mainAxisAlignment: skir.MainAxisAlignment.start,
              crossAxisAlignment: skir.CrossAxisAlignment.stretch,
            ),
          ),
        ),
      );
      final host = BoundPresentationHost(
        catalog: CheckedEditorCatalog(skir.EditorCatalog.defaultInstance),
        root: () => root,
        bindings: [
          BoundPresentationBinding(
            id: _binding,
            use: skir.TypeUse.wrapScalar(
              skir.ScalarKind.createInteger(
                width: skir.IntegerWidth.signedThirtyTwo,
              ),
            ),
            read: (_) => current,
            write: (_, value) {
              current = value;
              writes++;
              return const PortablePresentationWriteResult.applied();
            },
          ),
        ],
        budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
      );
      final panel = await tester.showRenderer(host);
      await panel.fieldAt(0).type("-");
      // The feedback shows once, between the edited field and its duplicate.
      final feedback = find.text("Enter a valid number");
      expect(feedback, findsOneWidget);
      expect(
        tester.getTopLeft(feedback).dy,
        greaterThanOrEqualTo(panel.fieldAt(0).rect.bottom),
      );
      expect(
        tester.getBottomLeft(feedback).dy,
        lessThanOrEqualTo(panel.fieldAt(1).rect.top),
      );
      expect(visibleFieldValues(), ["-", "3"]);
      expect(panel.fieldAt(0).isFocused, isTrue);
      expect(current, skir.DataValue.wrapInteger("3"));
      expect(writes, 0);
      await panel.fieldAt(0).type("7");
      expect(find.text("Enter a valid number"), findsNothing);
      expect(panel.fieldAt(0).isFocused, isTrue);
      expect(current, skir.DataValue.wrapInteger("7"));
      expect(writes, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("a replaced host ignores its pending rejection and status", (
    tester,
  ) async {
    final pending = Completer<PortablePresentationWriteResult>();
    final previous = DiagnosedTextHost(response: pending.future);
    final replacement = DiagnosedTextHost();
    final previousStatuses = <String>[];
    final replacementStatuses = <String>[];
    addTearDown(previous.dispose);
    addTearDown(replacement.dispose);
    final panel = await tester.showComponent(
      Material(
        child: PortablePresentationRenderer(
          host: previous,
          onStatus: previousStatuses.add,
        ),
      ),
    );
    await panel.fieldAt(0).type("rejected draft");
    expect(previous.requests, 1);
    await tester.showComponent(
      Material(
        child: PortablePresentationRenderer(
          host: replacement,
          onStatus: replacementStatuses.add,
        ),
      ),
    );
    pending.complete(
      PortablePresentationWriteResult.rejected([
        invalidValueDiagnostic([_title])
            .copyWith(message: "Old field rejection"),
        invalidValueDiagnostic(const [])
            .copyWith(message: "Old general rejection"),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.text("Old field rejection"), findsNothing);
    expect(find.text("Old general rejection"), findsNothing);
    expect(previousStatuses, isEmpty);
    expect(replacementStatuses, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    "a new catalog generation ignores a pending rejection and status",
    (tester) async {
      final pending = Completer<PortablePresentationWriteResult>();
      final host = DiagnosedTextHost(response: pending.future);
      final statuses = <String>[];
      addTearDown(host.dispose);
      final panel = await tester.showComponent(
        Material(
          child: PortablePresentationRenderer(
            host: host,
            onStatus: statuses.add,
          ),
        ),
      );
      await panel.fieldAt(0).type("rejected draft");
      expect(host.requests, 1);
      final previousGeneration = host.document.catalog.snapshot.generation;
      host.replaceGeneration("replacement");
      await tester.pumpAndSettle();
      expect(
        host.document.catalog.snapshot.generation,
        isNot(previousGeneration),
      );
      pending.complete(
        PortablePresentationWriteResult.rejected([
          invalidValueDiagnostic([_title])
              .copyWith(message: "Old catalog field rejection"),
          invalidValueDiagnostic(const [])
              .copyWith(message: "Old catalog general rejection"),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.text("Old catalog field rejection"), findsNothing);
      expect(find.text("Old catalog general rejection"), findsNothing);
      expect(statuses, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "an external value change permanently removes a displayed rejection",
    (tester) async {
      const message = "The value is invalid";
      final host = DiagnosedTextHost();
      final panel = await tester.showRenderer(host);
      await panel.fieldAt(0).type("rejected draft");
      expect(host.requests, 1);
      expect(find.text(message), findsOneWidget);
      final original = host.source.value;
      host.source.value = skir.DataValue.wrapStringValue("Externally changed");
      await tester.pumpAndSettle();
      expect(find.text(message), findsNothing);
      host.source.value = original;
      await tester.pumpAndSettle();
      expect(find.text(message), findsNothing);
      expect(host.requests, 1);
      expect(tester.takeException(), isNull);
    },
  );

  test("a correction wins over an older rejected response", () async {
    final operations = PortableOperationResults();
    addTearDown(operations.dispose);
    final olderResponse = Completer<PortablePresentationWriteResult>();
    final newerResponse = Completer<PortablePresentationWriteResult>();
    final older = operations.run(
      key: PortableOperationKey.write(_title),
      operation: () => olderResponse.future,
    );
    final newer = operations.run(
      key: PortableOperationKey.write(_title),
      operation: () => newerResponse.future,
    );
    newerResponse.complete(const PortablePresentationWriteResult.applied());
    await newer;
    olderResponse.complete(
      PortablePresentationWriteResult.rejected([
        invalidValueDiagnostic([_title]),
      ]),
    );
    await older;
    expect(operations.value.outcomes, isEmpty);
  });

  test("successful edits preserve independent field rejections", () async {
    final operations = PortableOperationResults();
    addTearDown(operations.dispose);
    final diagnostic = invalidValueDiagnostic([_title]);
    await operations.run(
      key: PortableOperationKey.write(_title),
      operation: () => PortablePresentationWriteResult.rejected([diagnostic]),
    );
    await operations.run(
      key: PortableOperationKey.write(_count),
      operation: () => const PortablePresentationWriteResult.applied(),
    );
    expect(operations.value.outcomes.keys, [
      PortableOperationKey.write(_title),
    ]);
    expect(operations.value.outcomes.values.single.diagnostics, [diagnostic]);
  });

  test(
    "a changed collection permanently retires its completed rejection",
    () async {
      final operations = PortableOperationResults();
      addTearDown(operations.dispose);
      final before = skir.DataValue.createListValue(items: const []);
      final after = skir.DataValue.createListValue(
        items: [
          skir.ListItem(
            id: skir.ItemId(value: "item:1"),
            value: skir.DataValue.wrapStringValue("new"),
          ),
        ],
      );
      var current = before;
      PortableDiagnosticObservation observe(PortableDiagnosticTarget target) {
        expect(target, _title);
        return PortableDiagnosticObservation(target: target, value: current);
      }

      final diagnostic = invalidValueDiagnostic([_title]);
      await operations.run(
        key: PortableOperationKey.addItem(_title),
        input: observe(_title),
        operation: () => PortablePresentationWriteResult.rejected([diagnostic]),
      );
      expect(operations.value.outcomes.values.single.diagnostics, [diagnostic]);
      expect(operations.value.obsoleteRequests(observe), isEmpty);
      current = after;
      operations.retire(operations.value.obsoleteRequests(observe));
      expect(operations.value.outcomes, isEmpty);
      current = before;
      expect(operations.value.obsoleteRequests(observe), isEmpty);
      expect(operations.value.outcomes, isEmpty);
    },
  );

  test(
    "retiring a pending request prevents its rejection from returning",
    () async {
      final operations = PortableOperationResults();
      addTearDown(operations.dispose);
      final response = Completer<PortablePresentationWriteResult>();
      final pending = operations.run(
        key: PortableOperationKey.addMapRow(_title),
        input: PortableDiagnosticObservation(
          target: _title,
          value: skir.DataValue.createMapValue(rows: const []),
        ),
        operation: () => response.future,
      );
      operations.retire({operations.value.outcomes.values.single.request});
      response.complete(
        PortablePresentationWriteResult.rejected([
          invalidValueDiagnostic([_title]),
        ]),
      );
      await pending;
      expect(operations.value.outcomes, isEmpty);
    },
  );

  test("an old retirement cannot erase a newer request", () async {
    final operations = PortableOperationResults();
    addTearDown(operations.dispose);
    final response = Completer<PortablePresentationWriteResult>();
    final pending = operations.run(
      key: PortableOperationKey.write(_title),
      operation: () => response.future,
    );
    final previous = operations.value.outcomes.values.single.request;
    final diagnostic = invalidValueDiagnostic([_title]);
    await operations.run(
      key: PortableOperationKey.write(_title),
      operation: () => PortablePresentationWriteResult.rejected([diagnostic]),
    );
    operations.retire({previous});
    response.complete(const PortablePresentationWriteResult.applied());
    await pending;
    expect(operations.value.outcomes.values.single.diagnostics, [diagnostic]);
  });

  test(
    "an unmounted input retains its rejection until a known value changes",
    () async {
      final operations = PortableOperationResults();
      addTearDown(operations.dispose);
      final diagnostic = invalidValueDiagnostic([_title]);
      await operations.run(
        key: PortableOperationKey.write(_title),
        input: PortableDiagnosticObservation(
          target: _title,
          value: skir.DataValue.wrapStringValue("original"),
        ),
        operation: () => PortablePresentationWriteResult.rejected([diagnostic]),
      );
      operations.retire(operations.value.obsoleteRequests((_) => null));
      expect(operations.value.outcomes.values.single.diagnostics, [diagnostic]);
      operations.retire(
        operations.value.obsoleteRequests(
          (target) =>
              PortableDiagnosticObservation(target: target, value: null),
        ),
      );
      expect(operations.value.outcomes, isEmpty);
    },
  );

  test("disposal ignores a delayed rejection and status callback", () async {
    final operations = PortableOperationResults();
    final messages = <String>[];
    operations.onStatus = messages.add;
    final response = Completer<PortablePresentationWriteResult>();
    final pending = operations.run(
      key: PortableOperationKey.write(_title),
      operation: () => response.future,
    );
    operations.dispose();
    response.complete(
      PortablePresentationWriteResult.rejected([
        invalidValueDiagnostic(const []),
      ]),
    );
    await pending;
    expect(messages, isEmpty);
  });

  for (final targets in [
    <PortableDiagnosticTarget>[],
    [_count],
  ]) {
    test(
      "unplaced resource findings retain ownership with targets: $targets",
      () {
        final diagnostic = invalidValueDiagnostic(targets);
        final placement = PortableDiagnosticPlacement.route(
          diagnostics: [diagnostic],
          diagnosticFallback: PortableDiagnosticFallback.resource,
          outcomes: const [],
          presentation: PortableDiagnosticPresentation(
            nodes: {Object(): diagnosticControl(_title)},
          ),
        );
        expect(placement.general, isEmpty);
        expect(placement.unplaced, [diagnostic]);
      },
    );
  }

  test("resource findings still reach fields and addressed headers", () {
    final control = Object();
    final header = Object();
    final diagnostic = invalidValueDiagnostic([_title, _count]);
    final placement = PortableDiagnosticPlacement.route(
      diagnostics: [diagnostic],
      diagnosticFallback: PortableDiagnosticFallback.resource,
      outcomes: const [],
      presentation: PortableDiagnosticPresentation(
        nodes: {
          control: diagnosticControl(_title),
          header: diagnosticHeader(_count),
        },
      ),
    );
    expect(placement.forAnchor(control).direct, [diagnostic]);
    expect(placement.forAnchor(header).direct, [diagnostic]);
    expect(placement.general, isEmpty);
    expect(placement.unplaced, isEmpty);
  });

  for (final localFirst in [false, true]) {
    test(
      "local feedback wins shared source ownership, local first: $localFirst",
      () {
        final diagnostic = invalidValueDiagnostic([_count]);
        final placement = PortableDiagnosticPlacement.route(
          diagnostics: [diagnostic],
          diagnosticFallback: localFirst
              ? PortableDiagnosticFallback.presentation
              : PortableDiagnosticFallback.resource,
          outcomes: const [],
          presentation: PortableDiagnosticPresentation(
            nodes: {
              Object(): PortableDiagnosticNode(
                kind: PortableDiagnosticNodeKind.source,
                diagnostics: [diagnostic],
                diagnosticFallback: localFirst
                    ? PortableDiagnosticFallback.resource
                    : PortableDiagnosticFallback.presentation,
              ),
            },
          ),
        );
        expect(placement.general, [diagnostic]);
        expect(placement.unplaced, isEmpty);
      },
    );
  }

  test(
    "an operation rejection keeps local fallback over resource validation",
    () {
      final diagnostic = invalidValueDiagnostic([_count]);
      final placement = PortableDiagnosticPlacement.route(
        diagnostics: [diagnostic],
        diagnosticFallback: PortableDiagnosticFallback.resource,
        outcomes: [
          PortableOperationOutcome(
            request: Object(),
            diagnostics: [diagnostic],
          ),
        ],
        presentation: const PortableDiagnosticPresentation(),
      );
      expect(placement.general, [diagnostic]);
      expect(placement.unplaced, isEmpty);
    },
  );

  test(
    "projected resource findings do not become parent presentation failures",
    () {
      final diagnostic = invalidValueDiagnostic([_count]);
      final placement = PortableDiagnosticPlacement.route(
        diagnostics: const [],
        outcomes: const [],
        presentation: PortableDiagnosticPresentation(
          nodes: {
            Object(): PortableDiagnosticNode(
              kind: PortableDiagnosticNodeKind.source,
              diagnostics: [diagnostic],
              diagnosticFallback: PortableDiagnosticFallback.resource,
            ),
          },
        ),
      );
      expect(placement.general, isEmpty);
      expect(placement.unplaced, [diagnostic]);
    },
  );

  test(
    "duplicated controls display one diagnostic while headers count it once",
    () {
      final header = Object();
      final first = Object();
      final duplicate = Object();
      final second = Object();
      final diagnostic = invalidValueDiagnostic([_title, _count]);
      final placement = PortableDiagnosticPlacement.route(
        diagnostics: [diagnostic, diagnostic],
        outcomes: const [],
        presentation: PortableDiagnosticPresentation(
          nodes: {
            header: const PortableDiagnosticNode(
              kind: PortableDiagnosticNodeKind.header,
            ),
            first: diagnosticControl(_title, parent: header),
            duplicate: diagnosticControl(_title, parent: header),
            second: diagnosticControl(_count, parent: header),
          },
        ),
      );
      expect(placement.forAnchor(first).direct, [diagnostic]);
      expect(placement.forAnchor(duplicate).direct, [diagnostic]);
      expect(placement.forAnchor(second).direct, [diagnostic]);
      expect(placement.forAnchor(header).descendantCount, 1);
      expect(placement.general, isEmpty);
    },
  );

  test("headers combine contained controls with an explicit data summary", () {
    final group = Object();
    final titleControl = Object();
    final recordSummary = Object();
    final unrelatedSection = Object();
    final title = PortableDiagnosticTarget.binding(
      skir.BindingRef(bindingId: _binding, path: editorRootPath.field("name")),
    );
    final diagnostic = invalidValueDiagnostic([title]);
    final placement = PortableDiagnosticPlacement.route(
      diagnostics: [diagnostic],
      outcomes: const [],
      presentation: PortableDiagnosticPresentation(
        nodes: {
          group: const PortableDiagnosticNode(
            kind: PortableDiagnosticNodeKind.header,
          ),
          titleControl: diagnosticControl(title, parent: group),
          recordSummary: diagnosticHeader(_title),
          unrelatedSection: diagnosticHeader(_count),
        },
      ),
    );
    expect(placement.forAnchor(titleControl).direct, [diagnostic]);
    expect(placement.forAnchor(group).descendants, [diagnostic]);
    expect(placement.forAnchor(recordSummary).descendants, [diagnostic]);
    expect(placement.forAnchor(unrelatedSection).isEmpty, isTrue);
    expect(placement.general, isEmpty);
  });

  test("an explicit scope does not exclude errors in contained controls", () {
    final section = Object();
    final control = Object();
    final diagnostic = invalidValueDiagnostic([_count]);
    final placement = PortableDiagnosticPlacement.route(
      diagnostics: [diagnostic],
      outcomes: const [],
      presentation: PortableDiagnosticPresentation(
        nodes: {
          section: diagnosticHeader(_title),
          control: diagnosticControl(_count, parent: section),
        },
      ),
    );
    expect(placement.forAnchor(control).direct, [diagnostic]);
    expect(placement.forAnchor(section).descendants, [diagnostic]);
    expect(placement.general, isEmpty);
  });

  test("a hidden field falls back to its nearest addressed header", () {
    final outer = Object();
    final inner = Object();
    final target = PortableDiagnosticTarget.binding(
      skir.BindingRef(
        bindingId: _binding,
        path: editorRootPath.field("group").field("name"),
      ),
    );
    final group = PortableDiagnosticTarget.binding(
      skir.BindingRef(bindingId: _binding, path: editorRootPath.field("group")),
    );
    final diagnostic = invalidValueDiagnostic([target]);
    final placement = PortableDiagnosticPlacement.route(
      diagnostics: [diagnostic],
      outcomes: const [],
      presentation: PortableDiagnosticPresentation(
        nodes: {
          outer: diagnosticHeader(_title),
          inner: diagnosticHeader(group, parent: outer),
        },
      ),
    );
    expect(placement.forAnchor(inner).direct, [diagnostic]);
    expect(placement.forAnchor(outer).direct, isEmpty);
    expect(placement.forAnchor(outer).descendants, [diagnostic]);
    expect(placement.general, isEmpty);
  });

  test("equal paths in different bindings and resources remain isolated", () {
    final titleControl = Object();
    final resourceControl = Object();
    final firstResource = PortableDiagnosticTarget.value(
      skir.ValueLocation(
        resource: skir.ResourceId(value: "resource:first"),
        path: editorRootPath,
      ),
    );
    final secondResource = PortableDiagnosticTarget.value(
      skir.ValueLocation(
        resource: skir.ResourceId(value: "resource:second"),
        path: editorRootPath,
      ),
    );
    final diagnostic = invalidValueDiagnostic([_count, secondResource]);
    final placement = PortableDiagnosticPlacement.route(
      diagnostics: [diagnostic],
      outcomes: const [],
      presentation: PortableDiagnosticPresentation(
        nodes: {
          titleControl: diagnosticControl(_title),
          resourceControl: diagnosticControl(firstResource),
        },
      ),
    );
    expect(placement.forAnchor(titleControl).isEmpty, isTrue);
    expect(placement.forAnchor(resourceControl).isEmpty, isTrue);
    expect(placement.general, [diagnostic]);
  });

  test(
    "projected source observations resolve descendant values before controls",
    () {
      final child = PortableDiagnosticTarget.binding(
        skir.BindingRef(
          bindingId: _binding,
          path: editorRootPath.field("name"),
        ),
      );
      final presentation = PortableDiagnosticPresentation(
        nodes: {
          Object(): PortableDiagnosticNode(
            kind: PortableDiagnosticNodeKind.source,
            observations: [
              PortableDiagnosticObservation(
                target: _title,
                value: skir.DataValue.createRecord(
                  fields: [
                    skir.FieldValue(
                      name: "name",
                      value: skir.DataValue.wrapStringValue("fresh"),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Object(): PortableDiagnosticNode(
            kind: PortableDiagnosticNodeKind.control,
            observations: [
              PortableDiagnosticObservation(
                target: child,
                value: skir.DataValue.wrapStringValue("stale"),
              ),
            ],
          ),
        },
      );
      expect(
        presentation.resolve(child)?.value,
        skir.DataValue.wrapStringValue("fresh"),
      );
    },
  );

  test(
    "local parser feedback contributes to headers without global duplication",
    () {
      final header = Object();
      final control = Object();
      final diagnostic = invalidValueDiagnostic([_title]);
      final placement = PortableDiagnosticPlacement.route(
        diagnostics: const [],
        outcomes: const [],
        presentation: PortableDiagnosticPresentation(
          nodes: {
            header: const PortableDiagnosticNode(
              kind: PortableDiagnosticNodeKind.header,
            ),
            control: diagnosticControl(
              _title,
              parent: header,
            ).copyWith(diagnostics: [diagnostic]),
          },
        ),
      );
      expect(placement.forAnchor(header).descendants, [diagnostic]);
      expect(placement.forAnchor(control).direct, isEmpty);
      expect(placement.general, isEmpty);
    },
  );
}

final _binding = skir.ExpressionBindingId(value: "title");
final _title = PortableDiagnosticTarget.binding(
  skir.BindingRef(bindingId: _binding, path: editorRootPath),
);
final _count = PortableDiagnosticTarget.binding(
  skir.BindingRef(
    bindingId: skir.ExpressionBindingId(value: "count"),
    path: editorRootPath,
  ),
);
