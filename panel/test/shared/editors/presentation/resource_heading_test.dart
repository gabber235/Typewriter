import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("resource heading fits and follows the host name binding", (
    tester,
  ) async {
    final name = skir.ExpressionBindingId(value: "title");
    var title = "Before";
    final owner = ChangeNotifier();
    final host = BoundPresentationHost(
      catalog: skir.EditorCatalog.defaultInstance.asTrustedLocalCatalog(),
      root: () => name.readExpression().resourceHeading(
        id: "resource",
        color: Colors.blue.portableExpression,
        identifier: "resource:1".portableExpression,
      ),
      bindings: [
        BoundPresentationBinding(
          id: name,
          use: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
          read: (_) => skir.DataValue.wrapStringValue(title),
          owner: owner,
        ),
      ],
      contextInputs: [panelSelectionCountInput],
      budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 100),
    );
    addTearDown(host.dispose);
    addTearDown(owner.dispose);
    await tester.showComponent(
      Material(
        child: SizedBox(
          width: 220,
          child: PortablePresentationRenderer(host: host),
        ),
      ),
    );
    expect(find.text("Before"), findsOneWidget);
    expect(find.text("resource:1"), findsOneWidget);
    expect(find.byType(AutoSizeText), findsOneWidget);
    expect(find.byType(SelectionArea), findsNWidgets(2));
    title = "After";
    owner.notifyListeners();
    await tester.pump();
    expect(find.text("After"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("pane context hides all stacked headings and restores them", (
    tester,
  ) async {
    final first = BoundPresentationHost(
      catalog: skir.EditorCatalog.defaultInstance.asTrustedLocalCatalog(),
      root: () => "Book".portableExpression.resourceHeading(
        id: "book",
        color: Colors.blue.portableExpression,
        identifier: "book:1".portableExpression,
      ),
      bindings: const [],
      contextInputs: [panelSelectionCountInput],
      budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 100),
    );
    final second = BoundPresentationHost(
      catalog: skir.EditorCatalog.defaultInstance.asTrustedLocalCatalog(),
      root: () => "Tag".portableExpression.resourceHeading(
        id: "tag",
        color: Colors.red.portableExpression,
        identifier: "tag:1".portableExpression,
      ),
      bindings: const [],
      contextInputs: [panelSelectionCountInput],
      budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 100),
    );
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    Future<void> pump(int count) => tester.showComponent(
      Material(
        child: PresentationEnvironment(
          host: HostContext(selectionCount: count),
          child: Column(
            children: [
              PortablePresentationRenderer(host: first),
              PortablePresentationRenderer(host: second),
              const Text("Fields remain"),
            ],
          ),
        ),
      ),
    );
    await pump(1);
    expect(find.text("book:1"), findsOneWidget);
    await pump(2);
    expect(find.byType(AutoSizeText), findsNothing);
    expect(find.text("book:1"), findsNothing);
    expect(find.text("tag:1"), findsNothing);
    expect(find.text("Fields remain"), findsOneWidget);
    await pump(1);
    expect(find.text("book:1"), findsOneWidget);
    expect(find.text("tag:1"), findsOneWidget);
  });

  testWidgets("environment reaches a custom scope builder", (tester) async {
    final host = BoundPresentationHost(
      catalog: skir.EditorCatalog.defaultInstance.asTrustedLocalCatalog(),
      root: () => "Resource".portableExpression.resourceHeading(
        id: "resource",
        color: Colors.blue.portableExpression,
      ),
      bindings: const [],
      contextInputs: [panelSelectionCountInput],
      budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 100),
    );
    addTearDown(host.dispose);
    var observed = false;
    await tester.showComponent(
      Material(
        child: PresentationEnvironment(
          host: const HostContext(selectionCount: 2),
          child: PortablePresentationRenderer(
            host: host,
            scopeBuilder:
                ({
                  required host,
                  required document,
                  required bindings,
                  required reportStatus,
                  required operations,
                }) {
                  observed =
                      bindings[panelSelectionCountInput.binding.id]?.value ==
                      skir.DataValue.wrapInteger("2");
                  return PortablePresentationScope(
                    operations: operations,
                    bindings: bindings,
                    budget: document.budget,
                    host: host,
                  );
                },
          ),
        ),
      ),
    );
    expect(observed, isTrue);
    expect(find.byType(AutoSizeText), findsNothing);
  });

  test("environment rejects collisions and writable observations", () {
    final surface = skir.ExpressionBindingId(value: "surface");
    final value = PortableExpressionBinding(
      value: skir.DataValue.wrapInteger("1"),
    );
    expect(
      () => {surface: value}.withPresentationEnvironment({surface: value}),
      throwsStateError,
    );
    expect(
      () => <skir.ExpressionBindingId, PortableExpressionBinding>{}
          .withPresentationEnvironment({
            surface: PortableExpressionBinding(
              value: value.value,
              location: skir.ValueLocation(
                resource: skir.ResourceId(value: "book:1"),
                path: skir.ValuePath(segments: const []),
              ),
            ),
          }),
      throwsStateError,
    );
  });

  test("field scopes clear identity and resource scopes supply their own", () {
    final root = skir.ExpressionBindingId(value: "root");
    final scope = PortablePresentationScope(
      operations: testPortableOperations(),
      bindings: {
        presentationSubjectIdentifierBindingId: PortableExpressionBinding(
          value: skir.DataValue.wrapStringValue("outer"),
        ),
        root: PortableExpressionBinding(
          value: skir.DataValue.createRecord(
            fields: [
              skir.FieldValue(
                name: "name",
                value: skir.DataValue.wrapStringValue("field"),
              ),
            ],
          ),
          location: skir.ValueLocation(
            resource: skir.ResourceId(value: "inner"),
            path: skir.ValuePath(segments: const []),
          ),
        ),
      },
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
    );
    final resource = scope.withConfiguredValue(
      skir.BindingRef(
        bindingId: root,
        path: skir.ValuePath(segments: const []),
      ),
    )!;
    expect(
      resource.bindings[presentationSubjectIdentifierBindingId]?.value,
      skir.ResourceId(value: "inner").toExpressionValue(),
    );
    final field = scope.withConfiguredValue(
      skir.BindingRef(
        bindingId: root,
        path: skir.ValuePath(
          segments: [skir.PathSegment.createField(name: "name")],
        ),
      ),
    )!;
    expect(
      field.bindings.containsKey(presentationSubjectIdentifierBindingId),
      isFalse,
    );
    expect(
      scope.bindings[presentationSubjectIdentifierBindingId]?.value,
      skir.DataValue.wrapStringValue("outer"),
    );
  });

  testWidgets("fit starts at maximum and shrinks to minimum with overflow", (
    tester,
  ) async {
    final node = presentationText(
      "text",
      "A medium title".portableExpression,
      sizing: skir.TextSizing.createFit(
        minimum: numberLiteral(18),
        maximum: numberLiteral(40),
      ),
      paragraph: _singleLine,
    );
    Future<void> pump(double width) => tester.showComponent(
      Material(
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: PortablePresentationNodeRenderer(
              node: node,
              scope: unboundPresentationScope(),
            ),
          ),
        ),
      ),
    );
    await pump(1200);
    expect(tester.paragraphOf("A medium title").scaledFontSize, 40);
    await pump(180);
    final smaller = tester.paragraphOf("A medium title");
    expect(smaller.scaledFontSize, inInclusiveRange(18, 39));
    await pump(30);
    expect(tester.paragraphOf("A medium title").scaledFontSize, 18);
    expect(
      tester.paragraphOf("A medium title").overflow,
      TextOverflow.ellipsis,
    );
    expect(find.byType(SelectionArea), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("ordinary and exact sizing retain the normal text path", (
    tester,
  ) async {
    for (final sizing in [
      null,
      skir.TextSizing.wrapExact(numberLiteral(22.5)),
    ]) {
      await tester.showComponent(
        Material(
          child: PortablePresentationNodeRenderer(
            node: presentationText(
              "text",
              "Ordinary".portableExpression,
              sizing: sizing,
              paragraph: _singleLine,
            ),
            scope: unboundPresentationScope(),
          ),
        ),
      );
      expect(find.byType(AutoSizeText), findsNothing);
      if (sizing != null) {
        expect(tester.paragraphOf("Ordinary").text.style?.fontSize, 22.5);
      }
    }
  });

  testWidgets("invalid fit bounds produce diagnostics before fitting", (
    tester,
  ) async {
    for (final sizing in [
      skir.TextSizing.createFit(
        minimum: numberLiteral(0),
        maximum: numberLiteral(40),
      ),
      skir.TextSizing.createFit(
        minimum: numberLiteral(40),
        maximum: numberLiteral(18),
      ),
      skir.TextSizing.createFit(
        minimum: numberLiteral(18.5),
        maximum: numberLiteral(40),
      ),
      skir.TextSizing.createFit(
        minimum: skir.ExpressionBindingId(value: "missing").readExpression(),
        maximum: numberLiteral(40),
      ),
    ]) {
      await tester.showComponent(
        Material(
          child: PortablePresentationNodeRenderer(
            node: presentationText(
              "text",
              "Invalid".portableExpression,
              sizing: sizing,
              paragraph: _singleLine,
            ),
            scope: unboundPresentationScope(),
          ),
        ),
      );
      expect(find.byType(AutoSizeText), findsNothing);
      expect(find.text("Invalid"), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets("rich fitted text preserves emphasis, direction and wrapping", (
    tester,
  ) async {
    final rich =
        (skir.RichTextContent.mutable()
              ..style = skir.TextStyleOverride(
                color: null,
                fontWeight: numberLiteral(600),
                fontItalic: null,
                decoration: null,
              )
              ..runs = [
                skir.TextRun(
                  text: "مرحبا ".portableExpression,
                  style: skir.TextStyleOverride(
                    color: skir.PresentationColor.wrapValue(
                      Colors.blue.portableExpression,
                    ),
                    fontWeight: null,
                    fontItalic: null,
                    decoration: null,
                  ),
                ),
                skir.TextRun(
                  text: "العالم".portableExpression,
                  style: skir.TextStyleOverride(
                    color: skir.PresentationColor.wrapValue(
                      Colors.red.portableExpression,
                    ),
                    fontWeight: numberLiteral(700),
                    fontItalic: numberLiteral(1),
                    decoration: "underline".portableExpression,
                  ),
                ),
              ]
              ..sizing = skir.TextSizing.createFit(
                minimum: numberLiteral(18),
                maximum: numberLiteral(40),
              )
              ..paragraph = skir.TextParagraph(
                maxLines: 2,
                overflow: skir.PresentationTextOverflow.clip,
                softWrap: true,
                selectable: true,
                tone: skir.PresentationTextTone.primary,
              ))
            .toFrozen();
    final node = skir.PresentationNode(
      nodeId: "rich",
      properties: skir.PresentationProperties.defaultInstance,
      header: null,
      element: skir.PresentationElement.wrapRichText(rich),
    );
    await tester.showComponent(
      Material(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SizedBox(
            width: 150,
            child: PortablePresentationNodeRenderer(
              node: node,
              scope: unboundPresentationScope(),
            ),
          ),
        ),
      ),
    );
    final paragraph = tester.paragraphOf("مرحبا العالم");
    expect(paragraph.textDirection, TextDirection.rtl);
    expect(paragraph.maxLines, 2);
    final span = paragraph.text as TextSpan;
    final authored = span.children!.single as TextSpan;
    final inherited = authored.children!.first as TextSpan;
    expect(inherited.style?.fontVariations, [FontVariation.weight(600)]);
    final emphasized = authored.children!.last as TextSpan;
    expect(emphasized.style?.color?.toARGB32(), Colors.red.toARGB32());
    expect(emphasized.style?.decoration, TextDecoration.underline);
    expect(emphasized.style?.fontVariations, [
      FontVariation.weight(700),
      FontVariation.italic(1),
    ]);
    expect(emphasized.style?.fontVariations, contains(FontVariation.italic(1)));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    "finite height and zero width retain the full text at the fit floor",
    (tester) async {
      final node = presentationText(
        "text",
        "Bounded".portableExpression,
        sizing: skir.TextSizing.createFit(
          minimum: numberLiteral(18),
          maximum: numberLiteral(40),
        ),
        paragraph: _singleLine,
      );
      await tester.showComponent(
        Material(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 400,
              height: 30,
              child: PortablePresentationNodeRenderer(
                node: node,
                scope: unboundPresentationScope(),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.paragraphOf("Bounded").scaledFontSize,
        inInclusiveRange(18, 39),
      );
      await tester.showComponent(
        Material(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 0,
              child: PortablePresentationNodeRenderer(
                node: node,
                scope: unboundPresentationScope(),
              ),
            ),
          ),
        ),
      );
      expect(tester.paragraphOf("Bounded").text.toPlainText(), "Bounded");
      expect(tester.paragraphOf("Bounded").scaledFontSize, 18);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("existing fitter keeps its linear accessibility approximation", (
    tester,
  ) async {
    Future<void> pump(skir.TextSizing sizing) => tester.showComponent(
      Material(
        child: MediaQuery(
          data: const MediaQueryData(textScaler: NonlinearTextScaler()),
          child: PortablePresentationNodeRenderer(
            node: presentationText(
              "text",
              "Scaled".portableExpression,
              sizing: sizing,
              paragraph: _singleLine,
            ),
            scope: unboundPresentationScope(),
          ),
        ),
      ),
    );
    await pump(skir.TextSizing.wrapExact(numberLiteral(40)));
    expect(tester.paragraphOf("Scaled").scaledFontSize, 72);
    await pump(
      skir.TextSizing.createFit(
        minimum: numberLiteral(18),
        maximum: numberLiteral(40),
      ),
    );
    expect(tester.paragraphOf("Scaled").scaledFontSize, closeTo(56, 0.001));
  });
}

final _singleLine = skir.TextParagraph(
  maxLines: 1,
  overflow: skir.PresentationTextOverflow.ellipsis,
  softWrap: false,
  selectable: true,
  tone: skir.PresentationTextTone.primary,
);
