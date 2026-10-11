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
    final borrowedClient = _TrackingClient();
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
      host: _TestHost(
        catalog: CheckedEditorCatalog(_emptyCatalog("catalog:static")),
        initial: skir.DataValue.wrapStringValue("Alpha"),
        onWrite: (value) => written = value,
      ),
    );

    await tester.pumpTestApp(
      child: Scaffold(
        body: PortableSearchInput(
          control: control,
          scope: scope,
          client: borrowedClient,
        ),
      ),
    );

    expect(find.text("Alpha"), findsOneWidget);
    expect(find.text("Beta").hitTestable(), findsNothing);

    await tester.tap(find.byKey(const ValueKey("authored_search_summary")));
    await tester.pumpAndSettle();

    expect(find.text("Beta"), findsOneWidget);
    await tester.tap(find.byType(EditableText));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(written, skir.DataValue.wrapStringValue("Beta"));

    await tester.tap(find.byKey(const ValueKey("authored_search_summary")));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(EditableText));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(written, skir.DataValue.wrapStringValue("Beta"));
    expect(find.text("Alpha").hitTestable(), findsNothing);

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
            host: _TestHost(
              catalog: CheckedEditorCatalog(_emptyCatalog("catalog:empty")),
              initial: skir.DataValue.wrapStringValue(""),
              onWrite: (value) => written = value,
            ),
          ),
        ),
      ),
    );

    expect(find.text("Search"), findsOneWidget);
    expect(find.text("Beta"), findsNothing);

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
      catalog: CheckedEditorCatalog(catalogSnapshot),
      host: _TestHost(
        catalog: CheckedEditorCatalog(catalogSnapshot),
        initial: skir.DataValue.unfilled,
        onWrite: (value) => written = value,
      ),
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
    expect(find.textContaining(r"$.results[1].name"), findsWidgets);
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

  testWidgets("late selection cannot close a rebound search input", (
    tester,
  ) async {
    final catalog = CheckedEditorCatalog(_emptyCatalog("catalog:pending"));
    final completion = Completer<PortablePresentationWriteResult>();
    final pendingHost = _TestHost(
      catalog: catalog,
      initial: skir.DataValue.unfilled,
      onWrite: (_) {},
      writeCompletion: completion,
    );
    final replacementHost = _TestHost(
      catalog: catalog,
      initial: skir.DataValue.unfilled,
      onWrite: (_) {},
    );
    PortablePresentationScope scope(PortablePresentationHost host) =>
        PortablePresentationScope(
          bindings: const {},
          budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
          catalog: catalog,
          host: host,
        );
    final control = _pendingControl();

    await tester.pumpTestApp(
      child: Scaffold(
        body: PortableSearchInput(
          control: control,
          scope: scope(pendingHost),
          client: _TrackingClient(),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey("authored_search_summary")));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Pending"));
    await tester.pump();

    await tester.pumpTestApp(
      child: Scaffold(
        body: PortableSearchInput(
          control: control,
          scope: scope(replacementHost),
          client: _TrackingClient(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    completion.complete(const PortablePresentationWriteResult.applied());
    await tester.pumpAndSettle();

    expect(find.text("Pending").hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

skir.SearchControl _pendingControl() {
  final target = skir.ExpressionBindingId(value: "target");
  final row = skir.ExpressionBindingId(value: "row");
  final rowRead = skir.ExpressionNode.createRead(
    binding: row,
    path: skir.ValuePath(segments: const []),
  );
  return skir.SearchControl(
    control: skir.BoundControl(
      binding: skir.BindingRef(
        bindingId: target,
        path: skir.ValuePath(segments: const []),
      ),
      label: null,
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
    provider: skir.SearchProvider.createStaticValues(
      values: skir.ExpressionNode.wrapLiteral(
        skir.DataValue.createListValue(
          items: [
            skir.ListItem(
              id: skir.ItemId(value: "pending"),
              value: skir.DataValue.wrapStringValue("Pending"),
            ),
          ],
        ),
      ),
      result: skir.SearchResultMapping(
        bindingId: row,
        key: rowRead,
        selectedValue: rowRead,
        presentation: skir.PresentationNode(
          nodeId: "pending",
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
        ),
        label: rowRead,
      ),
      selectors: const [],
    ),
    summary: null,
    placeholder: null,
    customValue: null,
    initialQuery: null,
  );
}

final class _TrackingClient extends MockClient {
  _TrackingClient()
    : super((_) async => Response("Unavailable in this fixture", 503));

  bool closed = false;

  @override
  void close() {
    closed = true;
    super.close();
  }
}

skir.EditorCatalogWireSnapshot _emptyCatalog(String generation) =>
    skir.EditorCatalogWireSnapshot(
      generation: skir.CatalogGeneration(value: generation),
      types: const [],
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

final class _TestHost extends ChangeNotifier
    implements PortablePresentationHost {
  _TestHost({
    required CheckedEditorCatalog catalog,
    required skir.DataValue initial,
    required this.onWrite,
    this.writeCompletion,
  }) : _value = initial,
       _document = PortablePresentationDocument(
         catalog: catalog,
         root: skir.PresentationNode.defaultInstance,
         bindings: const {},
         budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
       );

  skir.DataValue _value;
  final ValueChanged<skir.DataValue> onWrite;
  final Completer<PortablePresentationWriteResult>? writeCompletion;
  final PortablePresentationDocument _document;

  @override
  PortablePresentationCapabilities get capabilities =>
      const PortablePresentationCapabilities();
  @override
  PortablePresentationDocument get document => _document;
  @override
  bool get enabled => true;
  @override
  bool get readOnly => false;

  @override
  skir.TypeUse? expectedType(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => null;

  @override
  skir.ValueLocation? location(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => null;

  @override
  skir.DataValue? read(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => _value;

  @override
  Future<PortablePresentationWriteResult> write(
    skir.BindingRef reference,
    skir.DataValue value, {
    required PortableInvocationContext context,
  }) async {
    final delayed = writeCompletion;
    if (delayed != null) {
      final result = await delayed.future;
      if (result is PortablePresentationWriteRejected) return result;
    }
    _value = value;
    onWrite(value);
    return const PortablePresentationWriteResult.applied();
  }

  @override
  Future<PortablePresentationWriteResult> execute(
    skir.EditorAction editorAction, {
    required PortableInvocationContext context,
  }) async => const PortablePresentationWriteResult.rejected(
    "Actions are unavailable in this fixture",
  );
}
