import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("renders one section surface with semantic header and border", (
    tester,
  ) async {
    const accent = Color(0xFF967BFA);
    await tester.pumpTestApp(
      child: _renderer(
        PresentationNode(
          id: "section",
          header: PresentationHeader(
            title: "Quest conditions".asStringLiteral.asHeaderTitle,
            description: "Availability rules".asStringLiteral,
            initiallyExpanded: true,
          ),
          element: SectionElement(
            border: PresentationBorder.sides(
              start: PresentationBorderSide(
                color: TypedExpression(
                  resultType: NamedType(standardTypeRefs.color),
                  expression: LiteralExpression(
                    IntegerValue(BigInt.from(0xFF967BFA)),
                  ),
                ),
                width: 4,
              ),
              end: const PresentationBorderSide(width: 2),
            ),
            child: PresentationNode(
              id: "section.body",
              element: TextElement("Body".asStringLiteral),
            ),
          ),
        ),
      ),
    );

    expect(find.text("Quest conditions"), findsOneWidget);
    expect(find.text("Availability rules"), findsOneWidget);
    expect(find.text("Body", skipOffstage: false), findsOneWidget);
    expect(find.byType(DepthBox), findsOneWidget);

    final paint = tester.widget<CustomPaint>(_sectionBorderPaint);
    final dynamic painter = paint.foregroundPainter;
    expect(painter.border.start, const BorderSide(color: accent, width: 4));
    expect(painter.border.end.width, 2);
    expect(
      painter.border.end.color,
      Theme.of(tester.element(find.text("Body"))).colorScheme.outlineVariant,
    );

    await tester.tap(find.text("Quest conditions"));
    await tester.pumpAndSettle();

    expect(find.text("Body", skipOffstage: false), findsOneWidget);
  });

  testWidgets("preserves logical border direction in right to left layouts", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: _renderer(
          const PresentationNode(
            id: "rtl.section",
            element: SectionElement(
              border: PresentationBorder.sides(
                start: PresentationBorderSide(width: 3),
              ),
              child: PresentationNode(
                id: "rtl.body",
                element: TextElement(
                  TypedExpression(
                    resultType: StringType(),
                    expression: LiteralExpression(StringValue("RTL body")),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final paint = tester.widget<CustomPaint>(_sectionBorderPaint);
    final dynamic painter = paint.foregroundPainter;
    expect(painter.textDirection, TextDirection.rtl);
    expect(painter.border.start.width, 3);
    expect(painter.border.end, isNull);
  });

  testWidgets("uses default padding when a section header stays inline", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: _renderer(
        PresentationNode(
          id: "inline.section",
          header: PresentationHeader(
            title: "Inline section".asStringLiteral.asHeaderTitle,
          ),
          element: SectionElement(
            child: PresentationNode(
              id: "inline.section.body",
              element: TextElement("Inline body".asStringLiteral),
            ),
          ),
        ),
      ),
    );

    final spacing = tester
        .element(find.byType(PresentationHeaderChrome))
        .spacing;
    final headerPadding = EdgeInsets.symmetric(
      horizontal: spacing.space2,
      vertical: spacing.space1,
    );
    final bodyPadding = EdgeInsets.symmetric(
      horizontal: spacing.space2,
      vertical: spacing.space1,
    );

    expect(find.byType(Expansible), findsNothing);
    expect(
      find.ancestor(
        of: find.text("Inline section"),
        matching: find.byWidgetPredicate(
          (widget) => widget is Padding && widget.padding == headerPadding,
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.text("Inline body"),
        matching: find.byWidgetPredicate(
          (widget) => widget is Padding && widget.padding == bodyPadding,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets("allows header and content padding to be removed", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: _renderer(
        PresentationNode(
          id: "zero.padding.section",
          header: PresentationHeader(
            title: "Zero padding".asStringLiteral.asHeaderTitle,
            headerPadding: const PresentationInsets.all(0),
            contentPadding: const PresentationInsets.all(0),
          ),
          element: SectionElement(
            child: PresentationNode(
              id: "zero.padding.section.body",
              element: TextElement("Zero padding body".asStringLiteral),
            ),
          ),
        ),
      ),
    );

    final zeroPadding = find.byWidgetPredicate(
      (widget) => widget is Padding && widget.padding == EdgeInsets.zero,
    );

    expect(
      find.ancestor(of: find.text("Zero padding"), matching: zeroPadding),
      findsOneWidget,
    );
    expect(
      find.ancestor(of: find.text("Zero padding body"), matching: zeroPadding),
      findsOneWidget,
    );
  });

  testWidgets("renders directional presentation padding", (tester) async {
    await tester.pumpTestApp(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: _renderer(
          const PresentationNode(
            id: "padding",
            element: PaddingElement(
              top: 1,
              start: 12,
              end: 4,
              bottom: 2,
              child: PresentationNode(
                id: "padding.body",
                element: TextElement(
                  TypedExpression(
                    resultType: StringType(),
                    expression: LiteralExpression(StringValue("Padded")),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final padding = find.byWidgetPredicate(
      (widget) =>
          widget is Padding &&
          widget.padding == const EdgeInsetsDirectional.fromSTEB(12, 1, 4, 2),
    );
    expect(padding, findsOneWidget);
    expect(Directionality.of(tester.element(padding)), TextDirection.rtl);
  });

  testWidgets("container stretches and applies final presentation styling", (
    tester,
  ) async {
    const surfaceColor = Color(0x2E967BFA);
    const contentColor = Color(0xFF967BFA);
    await tester.pumpTestApp(
      child: SizedBox(
        width: 260,
        child: _renderer(
          PresentationNode(
            id: "container",
            element: ContainerElement(
              border: PresentationBorder.all(
                PresentationBorderSide(color: _colorExpression(contentColor)),
              ),
              backgroundColor: _colorExpression(surfaceColor),
              radius: const PresentationRadius.small(),
              child: PresentationNode(
                id: "container.content",
                element: TextElement(
                  "Contained".asStringLiteral,
                  color: _colorExpression(contentColor),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(const ValueKey("container"))).width, 260);
    expect(find.byType(DepthBox), findsNothing);
    final decoration = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((widget) => widget.decoration)
        .whereType<BoxDecoration>()
        .singleWhere((decoration) => decoration.color == surfaceColor);
    expect(decoration.borderRadius, BorderRadius.circular(4));
    expect(
      tester.widget<EditableText>(find.text("Contained")).style.color,
      contentColor,
    );
  });
}

TypedExpression _colorExpression(Color color) => TypedExpression(
  resultType: NamedType(standardTypeRefs.color),
  expression: LiteralExpression(IntegerValue(BigInt.from(color.toARGB32()))),
);

Finder get _sectionBorderPaint => find.byWidgetPredicate(
  (widget) =>
      widget is CustomPaint &&
      widget.foregroundPainter.runtimeType.toString() ==
          "_SectionBorderPainter",
);

EditorProtocolRenderer _renderer(PresentationNode presentation) {
  const root = ResolvedTypeRef(
    id: QualifiedTypeId(namespace: "test", name: "SectionRoot"),
    revision: 1,
  );
  return EditorProtocolRenderer(
    envelope: const TypedValueEnvelope(rootType: root, rootValue: UnitValue()),
    typeCatalog: const TypeCatalog([
      TypeDefinition(
        id: root,
        kind: NominalTypeKind.concrete,
        representation: UnitType(),
      ),
    ]),
    presentation: presentation,
  );
}
