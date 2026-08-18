import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  test("recovers an Iconify value from its typed representation", () {
    const icon = IconValue.iconify("mdi:sword");

    expect(icon.typedValue.iconValueOrNull, icon);
  });

  testWidgets("renders a sanitized SVG with accessible semantics", (
    tester,
  ) async {
    const icon = IconValue.svg(
      '<svg viewBox="0 0 24 24"><path d="M0 0h1v1z"/></svg>',
    );

    await tester.pumpTestApp(
      child: _renderer(
        icon: icon.typedValue,
        resultType: NamedType(standardTypeRefs.icon),
        semanticLabel: "Quest icon",
      ),
    );

    expect(find.bySemanticsLabel("Quest icon"), findsOneWidget);
    expect(find.textContaining("Icon content must"), findsNothing);
  });

  testWidgets("localizes values outside the Icon hierarchy", (tester) async {
    await tester.pumpTestApp(
      child: _renderer(
        icon: const StringValue("add"),
        resultType: const StringType(),
      ),
    );

    expect(find.byType(Icones), findsNothing);
    expect(
      find.text("Icon content must evaluate to the nominal Icon type"),
      findsOneWidget,
    );
  });

  testWidgets("shows a fallback for malformed SVG", (tester) async {
    await tester.pumpTestApp(child: const Icones("<svg><path d=\"M0\""));

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.broken_image), findsOneWidget);
  });
}

Widget _renderer({
  required DataValue icon,
  required TypeExpression resultType,
  String? semanticLabel,
}) {
  final root = ResolvedTypeRef(
    id: const QualifiedTypeId(namespace: "test", name: "iconContent"),
    revision: 1,
  );
  return EditorProtocolRenderer(
    envelope: TypedValueEnvelope(rootType: root, rootValue: const UnitValue()),
    typeCatalog: TypeCatalog([
      TypeDefinition(
        id: root,
        kind: NominalTypeKind.concrete,
        representation: const UnitType(),
      ),
    ]),
    presentation: PresentationNode(
      id: "icon",
      element: IconElement(
        name: TypedExpression(
          resultType: resultType,
          expression: LiteralExpression(icon),
        ),
        semanticLabel: semanticLabel?.asStringLiteral,
      ),
    ),
  );
}
