import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("hides the binding id from a custom select editor", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: _renderer(
        value: const StringValue("story"),
        presentation: PresentationNode(
          id: "select",
          element: SelectInputElement(
            control: const BoundControl(binding: _rootBinding),
            allowCustomValue: true,
            options: [
              SelectOption(
                id: "story",
                label: "Story".asStringLiteral,
                value: "story".asStringLiteral,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text("0"), findsNothing);
    expect(find.byType(AdaptiveChoiceControl<DataValue>), findsOneWidget);
    expect(
      tester.widget<FormattedTextField>(find.byType(FormattedTextField)).text,
      "story",
    );
  });

  testWidgets("hides the binding id from a typed field editor", (tester) async {
    await tester.pumpTestApp(
      child: _renderer(
        value: const StringValue("typed field value"),
        presentation: const PresentationNode(
          id: "typedField",
          element: TypedFieldElement(
            binding: _rootBinding,
            expectedType: StringType(),
          ),
        ),
      ),
    );

    expect(find.text("0"), findsNothing);
    expect(
      tester.widget<FormattedTextField>(find.byType(FormattedTextField)).text,
      "typed field value",
    );
  });

  testWidgets("hides the nominal type id from a named value editor", (
    tester,
  ) async {
    const namedType = ResolvedTypeRef(
      id: QualifiedTypeId(namespace: "widgetbook", name: "NamedValue"),
      revision: 1,
    );
    await tester.pumpTestApp(
      child: _renderer(
        type: const NamedType(namedType),
        value: const StringValue("custom:quest-value"),
        definitions: const [
          TypeDefinition(
            id: namedType,
            kind: NominalTypeKind.concrete,
            representation: StringType(),
          ),
        ],
        presentation: const PresentationNode(
          id: "namedInput",
          element: NamedInputElement(BoundControl(binding: _rootBinding)),
        ),
      ),
    );

    expect(find.text("Widgetbook::Named Value"), findsNothing);
    expect(
      tester.widget<FormattedTextField>(find.byType(FormattedTextField)).text,
      "custom:quest-value",
    );
  });
}

const _rootBinding = BindingReference(bindingId: BindingId(0));

EditorProtocolRenderer _renderer({
  required DataValue value,
  required PresentationNode presentation,
  TypeExpression type = const StringType(),
  List<TypeDefinition> definitions = const [],
}) {
  const root = ResolvedTypeRef(
    id: QualifiedTypeId(namespace: "test", name: "BoundValueRenderer"),
    revision: 1,
  );
  return EditorProtocolRenderer(
    envelope: TypedValueEnvelope(rootType: root, rootValue: value),
    typeCatalog: TypeCatalog([
      TypeDefinition(
        id: root,
        kind: NominalTypeKind.concrete,
        representation: type,
      ),
      ...definitions,
    ]),
    presentation: presentation,
  );
}
