import "package:flutter_test/flutter_test.dart";
import "package:http/testing.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../support/test_utils.dart";

void main() {
  testWidgets("renders static results and selects with the keyboard", (
    tester,
  ) async {
    final target = skir.ExpressionBindingId(value: "target");
    final row = skir.ExpressionBindingId(value: "row");
    skir.DataValue? written;
    final targetReference = skir.BindingRef(
      bindingId: target,
      path: skir.ValuePath(segments: const []),
    );
    final rowRead = skir.ExpressionNode.createRead(
      binding: row,
      path: skir.ValuePath(segments: const []),
    );
    final summaryBinding = skir.ExpressionBindingId(value: "summary");
    final summaryRead = skir.ExpressionNode.createRead(
      binding: summaryBinding,
      path: skir.ValuePath(segments: const []),
    );
    final resultNode = skir.PresentationNode(
      nodeId: "result",
      properties: skir.PresentationProperties.defaultInstance,
      element: skir.PresentationElement.createText(
        value: rowRead,
        color: null,
        sizing: null,
        fontWeight: null,
        fontItalic: null,
        fontOpticalSize: null,
        fontSlant: null,
        fontWidth: null,
        textAlignment: null,
        lineHeight: null,
        letterSpacing: null,
        decoration: null,
        semanticLabel: null,
        paragraph: skir.TextParagraph.defaultInstance,
      ),
      header: null,
    );
    final mapping = skir.SearchResultMapping(
      bindingId: row,
      key: rowRead,
      selectedValue: rowRead,
      presentation: resultNode,
      label: rowRead,
    );
    final control = skir.SearchControl(
      control: skir.BoundControl(
        binding: targetReference,
        label: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue("Choice"),
        ),
        description: null,
        prefix: null,
        semanticLabel: null,
      ),
      selectionMode: skir.SearchSelectionMode.single,
      queryBindingId: skir.ExpressionBindingId(value: "query"),
      summaryBindingId: summaryBinding,
      maximumExtent: skir.ExpressionNode.wrapLiteral(
        skir.DataValue.wrapInteger("240"),
      ),
      provider: skir.SearchProvider.createStaticValues(
        values: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.createListValue(
            items: [
              skir.ListItem(
                id: skir.ItemId(value: "alpha"),
                value: skir.DataValue.wrapStringValue("Alpha"),
              ),
              skir.ListItem(
                id: skir.ItemId(value: "beta"),
                value: skir.DataValue.wrapStringValue("Beta"),
              ),
            ],
          ),
        ),
        result: mapping,
        selectors: const [],
      ),
      summary: skir.PresentationNode(
        nodeId: "summary",
        properties: skir.PresentationProperties.defaultInstance,
        element: skir.PresentationElement.createText(
          value: summaryRead,
          color: null,
          sizing: null,
          fontWeight: null,
          fontItalic: null,
          fontOpticalSize: null,
          fontSlant: null,
          fontWidth: null,
          textAlignment: null,
          lineHeight: null,
          letterSpacing: null,
          decoration: null,
          semanticLabel: null,
          paragraph: skir.TextParagraph.defaultInstance,
        ),
        header: null,
      ),
      placeholder: null,
      customValue: null,
      initialQuery: null,
    );
    final scope = PortablePresentationScope(
      bindings: {
        target: PortableExpressionBinding(
          value: skir.DataValue.wrapStringValue("Alpha"),
        ),
      },
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
      setBinding: (_, value) => written = value,
    );

    await tester.pumpTestApp(
      child: Scaffold(
        body: PortableSearchInput(control: control, scope: scope),
      ),
    );

    expect(find.text("Alpha"), findsOneWidget);
    expect(find.text("Beta"), findsNothing);

    await tester.tap(find.byKey(const ValueKey("authored_search_summary")));
    await tester.pumpAndSettle();

    expect(find.text("Beta"), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey("authored_search_query")), findsNothing);
    expect(find.text("Beta"), findsNothing);
    expect(written, isNull);

    await tester.tap(find.byKey(const ValueKey("authored_search_summary")));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(written, skir.DataValue.wrapStringValue("Beta"));
    expect(find.byKey(const ValueKey("authored_search_query")), findsNothing);

    await tester.pumpTestApp(
      child: Scaffold(
        body: PortableSearchInput(
          control: control,
          scope: PortablePresentationScope(
            bindings: {
              target: PortableExpressionBinding(
                value: skir.DataValue.wrapStringValue(""),
              ),
            },
            budget: skir.EvaluationBudget(
              maxSteps: 100,
              maxCollectionItems: 100,
            ),
            setBinding: (_, value) => written = value,
          ),
        ),
      ),
    );

    expect(find.text("Search"), findsOneWidget);
    expect(find.text("Beta"), findsNothing);
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
    final catalogSnapshot = skir.EditorCatalogWireSnapshot(
      generation: skir.CatalogGeneration(value: "catalog:http"),
      types: [
        skir.PublishedType(
          display: null,
          definition: skir.TypeDefinition(
            id: resultType,
            parameters: const [],
            representation: skir.RepresentationTemplate.createRecord(
              fields: [
                skir.FieldDeclaration(
                  owner: skir.FieldOwner(definition: resultType, name: "name"),
                  type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
                  overrides: const [],
                  hasConstructorDefault: false,
                ),
              ],
              abstract_: false,
            ),
            parents: const [],
          ),
          status: skir.DeclarationStatus.ready,
          effectiveFields: [
            skir.EffectiveFieldTemplate(
              key: "name",
              owner: skir.FieldOwner(definition: resultType, name: "name"),
              type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
              rules: const [],
            ),
          ],
          ancestorTemplates: const [],
        ),
      ],
      relations: const [],
      resourceDefinitions: const [],
      presentations: const [],
      presentationMaterials: const [],
      configuration: const [],
      diagnostics: const [],
      initialization: const [],
      endpointBindings: const [],
      capabilities: const [],
      recommendations: const [],
      roleFallbacks: const [],
    );
    final rowRead = skir.ExpressionNode.createRead(
      binding: row,
      path: skir.ValuePath(segments: const []),
    );
    final resultNode = skir.PresentationNode(
      nodeId: "http_result",
      properties: skir.PresentationProperties.defaultInstance,
      element: skir.PresentationElement.createText(
        value: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue("HTTP result"),
        ),
        color: null,
        sizing: null,
        fontWeight: null,
        fontItalic: null,
        fontOpticalSize: null,
        fontSlant: null,
        fontWidth: null,
        textAlignment: null,
        lineHeight: null,
        letterSpacing: null,
        decoration: null,
        semanticLabel: null,
        paragraph: skir.TextParagraph.defaultInstance,
      ),
      header: null,
    );
    final control = skir.SearchControl(
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
      selectionMode: skir.SearchSelectionMode.single,
      queryBindingId: skir.ExpressionBindingId(value: "query"),
      summaryBindingId: skir.ExpressionBindingId(value: "summary"),
      maximumExtent: skir.ExpressionNode.wrapLiteral(
        skir.DataValue.wrapInteger("240"),
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
          bindingId: row,
          key: rowRead,
          selectedValue: rowRead,
          presentation: resultNode,
          label: null,
        ),
        contextBindings: const [],
        selectors: const [],
        timeoutMilliseconds: 1000,
      ),
      summary: null,
      placeholder: null,
      customValue: null,
      initialQuery: null,
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
      bindings: {
        target: const PortableExpressionBinding(value: skir.DataValue.unfilled),
      },
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
      setBinding: (_, value) => written = value,
      catalog: CheckedEditorCatalog(catalogSnapshot),
    );

    await tester.pumpTestApp(
      child: Scaffold(
        body: PortableSearchInput(
          control: control,
          scope: scope,
          client: client,
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey("authored_search_summary")));
    await tester.pumpAndSettle();

    expect(
      find.text("HTTP result"),
      findsOneWidget,
      reason: tester
          .widgetList<Text>(find.byType(Text))
          .map((widget) => widget.data)
          .toList()
          .toString(),
    );
    expect(find.textContaining(r"$.results[1].name"), findsOneWidget);
    await tester.tap(find.text("HTTP result"));
    await tester.pump();

    final named = written! as skir.DataValue_namedWrapper;
    expect(named.value.actualType.definition, resultType);
    final record = named.value.payload as skir.DataValue_recordWrapper;
    expect(
      record.value.fields.single.value,
      skir.DataValue.wrapStringValue("Alpha"),
    );
  });
}
