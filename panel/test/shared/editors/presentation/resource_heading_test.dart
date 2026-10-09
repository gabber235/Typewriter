import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("resource heading fits and follows the host name binding", (
    tester,
  ) async {
    final name = skir.ExpressionBindingId(value: "title");
    var title = "Before";
    final owner = ChangeNotifier();
    final host = _host(
      name.readExpression().resourceHeading(
        id: "resource",
        color: Colors.blue.portableExpression,
        identifier: "resource:1".portableExpression,
      ),
      bindings: [
        EditorSourcePresentationBinding(
          id: name,
          use: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
          read: (_) => skir.DataValue.wrapStringValue(title),
          owner: owner,
        ),
      ],
    );
    addTearDown(host.dispose);
    addTearDown(owner.dispose);
    await tester.pumpTestApp(
      child: Material(
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
    final first = _host(
      "Book".portableExpression.resourceHeading(
        id: "book",
        color: Colors.blue.portableExpression,
        identifier: "book:1".portableExpression,
      ),
    );
    final second = _host(
      "Tag".portableExpression.resourceHeading(
        id: "tag",
        color: Colors.red.portableExpression,
        identifier: "tag:1".portableExpression,
      ),
    );
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    Future<void> pump(int count) => tester.pumpTestApp(
      child: Material(
        child: PresentationEnvironment(
          bindings: {
            presentationSelectionCountBindingId: PortableExpressionBinding(
              value: skir.DataValue.wrapInteger(count.toString()),
            ),
          },
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
    final host = _host(
      "Resource".portableExpression.resourceHeading(
        id: "resource",
        color: Colors.blue.portableExpression,
      ),
    );
    addTearDown(host.dispose);
    var observed = false;
    await tester.pumpTestApp(
      child: Material(
        child: PresentationEnvironment(
          bindings: {
            presentationSelectionCountBindingId: PortableExpressionBinding(
              value: skir.DataValue.wrapInteger("2"),
            ),
          },
          child: PortablePresentationRenderer(
            host: host,
            scopeBuilder:
                ({
                  required host,
                  required document,
                  required bindings,
                  required setBinding,
                  required reportStatus,
                }) {
                  observed =
                      bindings[presentationSelectionCountBindingId]?.value ==
                      skir.DataValue.wrapInteger("2");
                  return PortablePresentationScope(
                    bindings: bindings,
                    budget: document.budget,
                    setBinding: setBinding,
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
    final value = PortableExpressionBinding(
      value: skir.DataValue.wrapInteger("1"),
    );
    expect(
      () => {presentationSelectionCountBindingId: value}
          .withPresentationEnvironment({
            presentationSelectionCountBindingId: value,
          }),
      throwsStateError,
    );
    expect(
      () => <skir.ExpressionBindingId, PortableExpressionBinding>{}
          .withPresentationEnvironment({
            presentationSelectionCountBindingId: PortableExpressionBinding(
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
      setBinding: (_, _) {},
    );
    final resource = scope.withConfiguredValue(
      skir.BindingRef(
        bindingId: root,
        path: skir.ValuePath(segments: const []),
      ),
    )!;
    expect(
      resource.bindings[presentationSubjectIdentifierBindingId]?.value,
      skir.DataValue.wrapStringValue("inner"),
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
    final node = _text("A medium title", sizing: _fit(18, 40));
    Future<void> pump(double width) => tester.pumpTestApp(
      child: Material(
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: PortablePresentationNodeRenderer(
              node: node,
              scope: _scope(),
            ),
          ),
        ),
      ),
    );
    await pump(1200);
    expect(_fontSize(_paragraph(tester, "A medium title")), 40);
    await pump(180);
    final smaller = _paragraph(tester, "A medium title");
    expect(_fontSize(smaller), inInclusiveRange(18, 39));
    await pump(30);
    expect(_fontSize(_paragraph(tester, "A medium title")), 18);
    expect(
      _paragraph(tester, "A medium title").overflow,
      TextOverflow.ellipsis,
    );
    expect(find.byType(SelectionArea), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("ordinary and exact sizing retain the normal text path", (
    tester,
  ) async {
    for (final sizing in [null, skir.TextSizing.wrapExact(_number(22.5))]) {
      await tester.pumpTestApp(
        child: Material(
          child: PortablePresentationNodeRenderer(
            node: _text("Ordinary", sizing: sizing),
            scope: _scope(),
          ),
        ),
      );
      expect(find.byType(AutoSizeText), findsNothing);
      if (sizing != null) {
        expect(_paragraph(tester, "Ordinary").text.style?.fontSize, 22.5);
      }
    }
  });

  testWidgets("invalid fit bounds produce diagnostics before fitting", (
    tester,
  ) async {
    for (final sizing in [
      _fit(0, 40),
      _fit(40, 18),
      _fit(18.5, 40),
      skir.TextSizing.createFit(
        minimum: skir.ExpressionBindingId(value: "missing").readExpression(),
        maximum: _number(40),
      ),
    ]) {
      await tester.pumpTestApp(
        child: Material(
          child: PortablePresentationNodeRenderer(
            node: _text("Invalid", sizing: sizing),
            scope: _scope(),
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
                fontWeight: _number(600),
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
                    fontWeight: _number(700),
                    fontItalic: _number(1),
                    decoration: "underline".portableExpression,
                  ),
                ),
              ]
              ..sizing = _fit(18, 40)
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
    await tester.pumpTestApp(
      child: Material(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SizedBox(
            width: 150,
            child: PortablePresentationNodeRenderer(
              node: node,
              scope: _scope(),
            ),
          ),
        ),
      ),
    );
    final paragraph = _paragraph(tester, "مرحبا العالم");
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
      final node = _text("Bounded", sizing: _fit(18, 40));
      await tester.pumpTestApp(
        child: Material(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 400,
              height: 30,
              child: PortablePresentationNodeRenderer(
                node: node,
                scope: _scope(),
              ),
            ),
          ),
        ),
      );
      expect(
        _fontSize(_paragraph(tester, "Bounded")),
        inInclusiveRange(18, 39),
      );
      await tester.pumpTestApp(
        child: Material(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 0,
              child: PortablePresentationNodeRenderer(
                node: node,
                scope: _scope(),
              ),
            ),
          ),
        ),
      );
      expect(_paragraph(tester, "Bounded").text.toPlainText(), "Bounded");
      expect(_fontSize(_paragraph(tester, "Bounded")), 18);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("existing fitter keeps its linear accessibility approximation", (
    tester,
  ) async {
    Future<void> pump(skir.TextSizing sizing) => tester.pumpTestApp(
      child: Material(
        child: MediaQuery(
          data: const MediaQueryData(textScaler: _NonlinearScaler()),
          child: PortablePresentationNodeRenderer(
            node: _text("Scaled", sizing: sizing),
            scope: _scope(),
          ),
        ),
      ),
    );
    await pump(skir.TextSizing.wrapExact(_number(40)));
    expect(_fontSize(_paragraph(tester, "Scaled")), 72);
    await pump(_fit(18, 40));
    expect(_fontSize(_paragraph(tester, "Scaled")), closeTo(56, 0.001));
  });
}

EditorSourcePresentationHost _host(
  skir.PresentationNode root, {
  List<EditorSourcePresentationBinding> bindings = const [],
}) => EditorSourcePresentationHost(
  catalog: skir.EditorCatalogWireSnapshot.defaultInstance
      .asTrustedLocalCatalog(),
  root: () => root,
  bindings: bindings,
  budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 100),
);
PortablePresentationScope _scope() => PortablePresentationScope(
  bindings: const {},
  budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 100),
  setBinding: (_, _) {},
);
skir.ExpressionNode _number(double value) =>
    skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapFloat(value));
skir.TextSizing _fit(double min, double max) =>
    skir.TextSizing.createFit(minimum: _number(min), maximum: _number(max));
skir.PresentationNode _text(String text, {skir.TextSizing? sizing}) =>
    skir.PresentationNode(
      nodeId: "text",
      properties: skir.PresentationProperties.defaultInstance,
      header: null,
      element: skir.PresentationElement.wrapText(
        (skir.TextContent.mutable()
              ..value = text.portableExpression
              ..sizing = sizing
              ..paragraph = skir.TextParagraph(
                maxLines: 1,
                overflow: skir.PresentationTextOverflow.ellipsis,
                softWrap: false,
                selectable: true,
                tone: skir.PresentationTextTone.primary,
              ))
            .toFrozen(),
      ),
    );
RenderParagraph _paragraph(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(
      find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText() == text,
      ),
    );

double _fontSize(RenderParagraph paragraph) =>
    paragraph.textScaler.scale(paragraph.text.style!.fontSize!);

class _NonlinearScaler extends TextScaler {
  const _NonlinearScaler();
  @override
  double scale(double fontSize) => fontSize * (fontSize > 30 ? 1.8 : 1.4);
  @override
  double get textScaleFactor => 1.4;
}
