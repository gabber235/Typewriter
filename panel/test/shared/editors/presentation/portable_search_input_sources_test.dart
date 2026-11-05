import "package:flutter_test/flutter_test.dart";
import "package:http/testing.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets(
    "configured search typography result placement and empty guidance reach the inline surface",
    (tester) async {
      skir.ExpressionNode text(String value) => skir.ExpressionNode.wrapLiteral(
        skir.DataValue.wrapStringValue(value),
      );
      final control =
          (staticSearchControl(
                  target: skir.BindingRef(
                    bindingId: _target,
                    path: editorRootPath,
                  ),
                  maximumExtent: 240,
                  choices: {
                    for (final value in const ["Pending"])
                      value.toLowerCase(): skir.DataValue.wrapStringValue(
                        value,
                      ),
                  },
                  summary: presentationText(
                    "summary",
                    inputExpression(_summary.id),
                  ),
                ).toMutable()
                ..provider = skir.SearchProvider.createStaticValues(
                  values: skir.ExpressionNode.wrapLiteral(
                    skir.DataValue.createListValue(items: const []),
                  ),
                  result:
                      (staticSearchControl(
                                target: skir.BindingRef(
                                  bindingId: _target,
                                  path: editorRootPath,
                                ),
                                maximumExtent: 240,
                                choices: {
                                  for (final value in const ["Pending"])
                                    value.toLowerCase():
                                        skir.DataValue.wrapStringValue(value),
                                },
                                summary: presentationText(
                                  "summary",
                                  inputExpression(_summary.id),
                                ),
                              ).provider
                              as skir.SearchProvider_staticValuesWrapper)
                          .value
                          .result,
                  selectors: const [],
                )
                ..appearance =
                    (skir.InputAppearance.mutable()
                          ..density = skir.ControlDensity.compact
                          ..valueStyle =
                              (skir.InputTextStyle.mutable()..weight = 500)
                                  .toFrozen())
                        .toFrozen()
                ..content =
                    (skir.InputContent.mutable()
                          ..placeholder = text("Find reward")
                          ..leading = skir.InputAdornment.none)
                        .toFrozen()
                ..popup =
                    (skir.PopupAppearance.mutable()
                          ..maximumWidth = skir.ExpressionNode.wrapLiteral(
                            skir.DataValue.wrapFloat(480),
                          )
                          ..maximumExtent = skir.ExpressionNode.wrapLiteral(
                            skir.DataValue.wrapFloat(200),
                          )
                          ..padding = skir.PresentationInsets.wrapAll(6))
                        .toFrozen()
                ..popupSide = skir.PopupSide.above
                ..emptyText = text("No matching rewards"))
              .toFrozen();
      final target = skir.ExpressionBindingId(value: "target");
      final scope = PortablePresentationScope(
        operations: testPortableOperations(),
        bindings: {
          target: PortableExpressionBinding(
            value: skir.DataValue.wrapStringValue(""),
          ),
        },
        budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
        host: FakePresentationHost(
          document: FakePresentationHost.emptyDocument(
            catalog: CheckedEditorCatalog(
              testCatalogSnapshot(
                generation: skir.CatalogGeneration(value: "configured.search"),
              ),
            ),
          ),
          value: skir.DataValue.wrapStringValue(""),
          onWrite: (_, _) {},
        ),
      );
      final panel = await tester.showComponent(
        Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: 360,
              child: PortableSearchInput(control: control, scope: scope),
            ),
          ),
        ),
      );
      await panel.tapOn(panel.searchInput.summaryButton);
      expect(find.text("Find reward"), findsOneWidget);
      // The result surface has no semantics of its own; its extent is only
      // reachable through the widget.
      expect(
        tester.getBottomLeft(find.byType(SearchTreeResults)).dy,
        lessThanOrEqualTo(panel.fieldAt(0).rect.top),
      );
      expect(
        tester.getSize(find.byType(SearchTreeResults)).height,
        lessThanOrEqualTo(200),
      );
      await panel.fieldAt(0).type("NoMatches");
      await tester.pump(const Duration(milliseconds: 500));
      await panel.settle();
      expect(find.text("No matching rewards"), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("static results appear only once the search opens", (
    tester,
  ) async {
    final panel = await showAlphaBetaSearch(tester);
    expect(find.text("Alpha"), findsOneWidget);
    expect(find.text("Beta").hitTestable(), findsNothing);

    await panel.tapOn(panel.searchInput.summaryButton);
    expect(find.text("Beta"), findsOneWidget);
  });

  testWidgets("Tab and Enter choose a result with the keyboard", (
    tester,
  ) async {
    skir.DataValue? written;
    final panel = await showAlphaBetaSearch(
      tester,
      onWrite: (value) => written = value,
    );
    await panel.tapOn(panel.searchInput.summaryButton);
    await panel.fieldAt(0).focus();
    await panel.press(LogicalKeyboardKey.tab);
    await panel.press(LogicalKeyboardKey.tab);
    await panel.press(LogicalKeyboardKey.enter);

    expect(written, skir.DataValue.wrapStringValue("Beta"));
  });

  testWidgets("Escape closes the search without choosing", (tester) async {
    skir.DataValue? written;
    final panel = await showAlphaBetaSearch(
      tester,
      onWrite: (value) => written = value,
    );
    await panel.tapOn(panel.searchInput.summaryButton);
    await panel.fieldAt(0).focus();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await panel.press(LogicalKeyboardKey.escape);

    expect(written, isNull);
    expect(find.text("Beta").hitTestable(), findsNothing);
    expect(find.text("Alpha"), findsOneWidget);
  });

  testWidgets("an empty value shows the default placeholder", (tester) async {
    await showAlphaBetaSearch(tester, value: "");

    expect(find.text("Search"), findsOneWidget);
    expect(find.text("Beta"), findsNothing);
  });

  testWidgets("a borrowed client outlives the search input", (tester) async {
    final borrowedClient = UnavailableHttpClient();
    await showAlphaBetaSearch(tester, client: borrowedClient);

    await tester.pumpWidget(const SizedBox());
    expect(borrowedClient.closed, isFalse);
  });

  testWidgets("decodes typed HTTP results and isolates malformed candidates", (
    tester,
  ) async {
    final target = skir.ExpressionBindingId(value: "target");
    final row = skir.ExpressionBindingId(value: "row");
    final resultType = skir.TypeDefinitionId(
      typeId: skir.TypeId.createQualified(namespace: "test", name: "Result"),
      revision: 1,
    );
    final catalogSnapshot = testCatalogSnapshot(
      generation: skir.CatalogGeneration(value: "catalog:http"),
      types: [
        declaredRecord(
          resultType,
          fields: {"name": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text)},
        ),
      ],
    );
    final rowRead = skir.ExpressionNode.createInput(
      binding: row,
      path: skir.ValuePath(segments: const []),
    );
    final resultNode = skir.PresentationNode(
      nodeId: "http_result",
      properties: skir.PresentationProperties.defaultInstance,
      element: textElement(
        skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue("HTTP result"),
        ),
      ),
      header: null,
    );
    final control = searchControl(
      control: skir.BoundControl(
        binding: skir.BindingRef(
          bindingId: target,
          path: skir.ValuePath(segments: const []),
        ),
        label: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue("Remote choice"),
        ),
        description: null,
        prefix: null,
        semanticLabel: null,
      ),
      provider: skir.SearchProvider.createHttpJson(
        uri: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue("https://example.test/search"),
        ),
        parameters: const [],
        resultPath: r"$.items[*]",
        resultType: skir.TypeTemplate.createNamed(
          definition: resultType,
          arguments: const [],
        ),
        result: skir.SearchResultMapping(
          binding: skir.BindingDeclaration(
            id: row,
            type: skir.TypeTemplate.createNamed(
              definition: resultType,
              arguments: const [],
            ),
          ),
          key: rowRead,
          selectedValue: rowRead,
          presentation: resultNode,
          label: null,
        ),
        contextBindings: const [],
        selectors: const [],
        timeoutMilliseconds: 1000,
      ),
      queryBinding: _query,
      summaryBinding: _summary,
      maximumExtent: 240,
    );
    skir.DataValue? written;
    final client = MockClient((request) async {
      expect(request.method, "GET");
      expect(request.url, Uri.parse("https://example.test/search"));
      expect(request.headers["Accept"], "application/json");
      return Response(
        jsonEncode({
          "items": [
            {"name": "Alpha"},
            {"name": 12},
          ],
        }),
        200,
        request: request,
        headers: const {"content-type": "application/json"},
      );
    });
    final scope = PortablePresentationScope(
      operations: testPortableOperations(),
      bindings: {
        target: const PortableExpressionBinding(value: skir.DataValue.unfilled),
      },
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
      catalog: CheckedEditorCatalog(catalogSnapshot),
      host: FakePresentationHost(
        document: FakePresentationHost.emptyDocument(
          catalog: CheckedEditorCatalog(catalogSnapshot),
        ),
        value: skir.DataValue.unfilled,
        onWrite: (_, value) => written = value,
      ),
    );

    final panel = await tester.showComponent(
      Scaffold(
        body: PortableSearchInput(
          control: control,
          scope: scope,
          client: client,
        ),
      ),
    );
    await panel.tapOn(panel.searchInput.summaryButton);

    expect(find.text("HTTP result"), findsOneWidget);
    expect(find.textContaining(r"$.results[1].name"), findsWidgets);
    await tester.tapAt(tester.getCenter(find.text("HTTP result")));
    await tester.pump();

    final named = written! as skir.DataValue_namedWrapper;
    expect(named.value.actualType.definition, resultType);
    final record = named.value.payload as skir.DataValue_recordWrapper;
    expect(
      record.value.fields.single.value,
      skir.DataValue.wrapStringValue("Alpha"),
    );
  });

  testWidgets("late selection cannot close a rebound search input", (
    tester,
  ) async {
    final catalog = CheckedEditorCatalog(
      testCatalogSnapshot(
        generation: skir.CatalogGeneration(value: "catalog:pending"),
      ),
    );
    final completion = Completer<PortablePresentationWriteResult>();
    final pendingHost = FakePresentationHost(
      document: FakePresentationHost.emptyDocument(catalog: catalog),
      value: skir.DataValue.unfilled,
      onWrite: (_, _) {},
      writeGate: completion,
    );
    final replacementHost = FakePresentationHost(
      document: FakePresentationHost.emptyDocument(catalog: catalog),
      value: skir.DataValue.unfilled,
      onWrite: (_, _) {},
    );
    PortablePresentationScope scope(PortablePresentationHost host) =>
        PortablePresentationScope(
          operations: testPortableOperations(),
          bindings: const {},
          budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
          catalog: catalog,
          host: host,
        );
    final control = staticSearchControl(
      target: skir.BindingRef(bindingId: _target, path: editorRootPath),
      maximumExtent: 240,
      choices: {
        for (final value in const ["Pending"])
          value.toLowerCase(): skir.DataValue.wrapStringValue(value),
      },
      summary: presentationText("summary", inputExpression(_summary.id)),
    );

    final panel = await tester.showComponent(
      Scaffold(
        body: PortableSearchInput(
          control: control,
          scope: scope(pendingHost),
          client: UnavailableHttpClient(),
        ),
      ),
    );
    await panel.tapOn(panel.searchInput.summaryButton);
    await tester.tapAt(tester.getCenter(find.text("Pending")));
    await tester.pump();

    await tester.showComponent(
      Scaffold(
        body: PortableSearchInput(
          control: control,
          scope: scope(replacementHost),
          client: UnavailableHttpClient(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    completion.complete(const PortablePresentationWriteResult.applied());
    await tester.pumpAndSettle();

    // The search stays open with its result still offered as a choice.
    expect(panel.fieldAt(0).exists, isTrue);
    expect(
      find.semantics.byPredicate(
        (node) =>
            node.isButton &&
            !node.isInvisible &&
            node.descendants.any((child) => child.spoken == "Pending"),
      ),
      findsOne,
    );
    expect(tester.takeException(), isNull);
  });
}

final _target = skir.ExpressionBindingId(value: "target");

final _text = skir.TypeTemplate.wrapScalar(skir.ScalarKind.text);
final _query = skir.BindingDeclaration(
  id: skir.ExpressionBindingId(value: "query"),
  type: _text,
);
final _summary = skir.BindingDeclaration(
  id: skir.ExpressionBindingId(value: "summary"),
  type: _text,
);
