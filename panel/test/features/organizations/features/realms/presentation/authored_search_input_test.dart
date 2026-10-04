import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/binding.dart"
    as binding;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/catalog.dart"
    as catalog;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/expression.dart"
    as expression;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/presentation.dart"
    as presentation;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../support/test_utils.dart";

void main() {
  testWidgets("renders static results and selects with the keyboard", (
    tester,
  ) async {
    final target = types.ExpressionBindingId(value: "target");
    final row = types.ExpressionBindingId(value: "row");
    types.DataValue? written;
    final targetReference = binding.BindingRef(
      bindingId: target,
      path: types.ValuePath(segments: const []),
    );
    final rowRead = expression.ExpressionNode.createRead(
      binding: row,
      path: types.ValuePath(segments: const []),
    );
    final summaryBinding = types.ExpressionBindingId(value: "summary");
    final summaryRead = expression.ExpressionNode.createRead(
      binding: summaryBinding,
      path: types.ValuePath(segments: const []),
    );
    final resultNode = presentation.PresentationNode(
      nodeId: "result",
      properties: presentation.PresentationProperties.defaultInstance,
      element: presentation.PresentationElement.createText(
        value: rowRead,
        color: null,
        fontSize: null,
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
        paragraph: presentation.TextParagraph.defaultInstance,
      ),
      header: null,
    );
    final mapping = presentation.SearchResultMapping(
      bindingId: row,
      key: rowRead,
      selectedValue: rowRead,
      presentation: resultNode,
      label: rowRead,
    );
    final control = presentation.SearchControl(
      control: presentation.BoundControl(
        binding: targetReference,
        label: expression.ExpressionNode.wrapLiteral(
          types.DataValue.wrapStringValue("Choice"),
        ),
        description: null,
        prefix: null,
        semanticLabel: null,
      ),
      selectionMode: presentation.SearchSelectionMode.single,
      queryBindingId: types.ExpressionBindingId(value: "query"),
      summaryBindingId: summaryBinding,
      maximumExtent: expression.ExpressionNode.wrapLiteral(
        types.DataValue.wrapInteger("240"),
      ),
      provider: presentation.SearchProvider.createStaticValues(
        values: expression.ExpressionNode.wrapLiteral(
          types.DataValue.createListValue(
            items: [
              types.ListItem(
                id: types.ItemId(value: "alpha"),
                value: types.DataValue.wrapStringValue("Alpha"),
              ),
              types.ListItem(
                id: types.ItemId(value: "beta"),
                value: types.DataValue.wrapStringValue("Beta"),
              ),
            ],
          ),
        ),
        result: mapping,
        selectors: const [],
      ),
      summary: presentation.PresentationNode(
        nodeId: "summary",
        properties: presentation.PresentationProperties.defaultInstance,
        element: presentation.PresentationElement.createText(
          value: summaryRead,
          color: null,
          fontSize: null,
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
          paragraph: presentation.TextParagraph.defaultInstance,
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
          value: types.DataValue.wrapStringValue("Alpha"),
        ),
      },
      budget: expression.EvaluationBudget(
        maxSteps: 100,
        maxCollectionItems: 100,
      ),
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

    expect(written, types.DataValue.wrapStringValue("Beta"));
    expect(find.byKey(const ValueKey("authored_search_query")), findsNothing);

    await tester.pumpTestApp(
      child: Scaffold(
        body: PortableSearchInput(
          control: control,
          scope: PortablePresentationScope(
            bindings: {
              target: PortableExpressionBinding(
                value: types.DataValue.wrapStringValue(""),
              ),
            },
            budget: expression.EvaluationBudget(
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
    final target = types.ExpressionBindingId(value: "target");
    final row = types.ExpressionBindingId(value: "row");
    final resultType = types.TypeDefinitionId(
      typeId: types.TypeId.createQualified(namespace: "test", name: "Result"),
      revision: 1,
    );
    final catalogSnapshot = catalog.EditorCatalogWireSnapshot(
      generation: types.CatalogGeneration(value: "catalog:http"),
      types: [
        catalog.PublishedType(
          display: null,
          definition: types.TypeDefinition(
            id: resultType,
            parameters: const [],
            representation: types.RepresentationTemplate.createRecord(
              fields: [
                types.FieldDeclaration(
                  owner: types.FieldOwner(definition: resultType, name: "name"),
                  type: types.TypeTemplate.wrapScalar(types.ScalarKind.text),
                  overrides: const [],
                  hasConstructorDefault: false,
                ),
              ],
              abstract_: false,
            ),
            parents: const [],
          ),
          status: catalog.DeclarationStatus.ready,
          effectiveFields: [
            catalog.EffectiveFieldTemplate(
              key: "name",
              owner: types.FieldOwner(definition: resultType, name: "name"),
              type: types.TypeTemplate.wrapScalar(types.ScalarKind.text),
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
    final rowRead = expression.ExpressionNode.createRead(
      binding: row,
      path: types.ValuePath(segments: const []),
    );
    final resultNode = presentation.PresentationNode(
      nodeId: "http_result",
      properties: presentation.PresentationProperties.defaultInstance,
      element: presentation.PresentationElement.createText(
        value: expression.ExpressionNode.wrapLiteral(
          types.DataValue.wrapStringValue("HTTP result"),
        ),
        color: null,
        fontSize: null,
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
        paragraph: presentation.TextParagraph.defaultInstance,
      ),
      header: null,
    );
    final control = presentation.SearchControl(
      control: presentation.BoundControl(
        binding: binding.BindingRef(
          bindingId: target,
          path: types.ValuePath(segments: const []),
        ),
        label: expression.ExpressionNode.wrapLiteral(
          types.DataValue.wrapStringValue("Remote choice"),
        ),
        description: null,
        prefix: null,
        semanticLabel: null,
      ),
      selectionMode: presentation.SearchSelectionMode.single,
      queryBindingId: types.ExpressionBindingId(value: "query"),
      summaryBindingId: types.ExpressionBindingId(value: "summary"),
      maximumExtent: expression.ExpressionNode.wrapLiteral(
        types.DataValue.wrapInteger("240"),
      ),
      provider: presentation.SearchProvider.createHttpJson(
        uri: expression.ExpressionNode.wrapLiteral(
          types.DataValue.wrapStringValue("https://example.test/search"),
        ),
        parameters: const [],
        resultPath: r"$.items[*]",
        resultType: types.TypeTemplate.createNamed(
          definition: resultType,
          arguments: const [],
        ),
        result: presentation.SearchResultMapping(
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
    types.DataValue? written;
    final client = MockClient((request) async {
      expect(request.method, "GET");
      expect(request.url, Uri.parse("https://example.test/search"));
      expect(request.headers["Accept"], "application/json");
      return http.Response(
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
        target: const PortableExpressionBinding(
          value: types.DataValue.unfilled,
        ),
      },
      budget: expression.EvaluationBudget(
        maxSteps: 100,
        maxCollectionItems: 100,
      ),
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

    final named = written! as types.DataValue_namedWrapper;
    expect(named.value.actualType.definition, resultType);
    final record = named.value.payload as types.DataValue_recordWrapper;
    expect(
      record.value.fields.single.value,
      types.DataValue.wrapStringValue("Alpha"),
    );
  });
}
