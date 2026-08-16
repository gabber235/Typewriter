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
}

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
