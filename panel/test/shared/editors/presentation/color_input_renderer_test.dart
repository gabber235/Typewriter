import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("renders and updates a concrete unsigned color value", (
    tester,
  ) async {
    await tester.pumpTestApp(child: _colorRenderer());

    expect(find.byType(ColorPickerField), findsOneWidget);
    expect(
      tester.widget<ColorPickerField>(find.byType(ColorPickerField)).color,
      const Color(0x807C4DFF),
    );

    await tester.enterText(find.byType(TextFormField), "#FF112233");
    await tester.pumpAndSettle();
    expect(
      tester.widget<ColorPickerField>(find.byType(ColorPickerField)).color,
      const Color(0xFF112233),
    );
  });

  testWidgets("rejects nominal values without unsigned 32 bit storage", (
    tester,
  ) async {
    final invalid = ResolvedTypeRef(
      id: const QualifiedTypeId(namespace: "test", name: "InvalidColor"),
      revision: 1,
    );
    await tester.pumpTestApp(
      child: _colorRenderer(
        colorType: invalid,
        colorDefinition: TypeDefinition(
          id: invalid,
          kind: NominalTypeKind.concrete,
          representation: const StringType(),
        ),
        value: const StringValue("purple"),
      ),
    );

    expect(
      find.text("Color control requires a concrete unsigned 32 bit value"),
      findsOneWidget,
    );
    expect(find.byType(ColorPickerField), findsNothing);
  });
}

const _rootBinding = BindingReference(bindingId: BindingId(0));

Widget _colorRenderer({
  ResolvedTypeRef? colorType,
  TypeDefinition? colorDefinition,
  DataValue? value,
}) {
  final root = ResolvedTypeRef(
    id: const QualifiedTypeId(namespace: "test", name: "ColorInput"),
    revision: 1,
  );
  final effectiveType = colorType ?? standardTypeRefs.color;
  return EditorProtocolRenderer(
    envelope: TypedValueEnvelope(
      rootType: root,
      rootValue: value ?? IntegerValue(BigInt.from(0x807C4DFF)),
    ),
    typeCatalog: TypeCatalog([
      TypeDefinition(
        id: root,
        kind: NominalTypeKind.concrete,
        representation: NamedType(effectiveType),
      ),
      ?colorDefinition,
    ]),
    presentation: const PresentationNode(
      id: "color",
      element: ColorInputElement(
        control: BoundControl(binding: _rootBinding),
        includeAlpha: true,
      ),
    ),
  );
}
