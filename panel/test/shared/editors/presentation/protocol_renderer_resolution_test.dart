import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("substitutes generic presentation parameters", (tester) async {
    const presentationId = PresentationId(
      namespace: "test",
      name: "box.default",
    );
    final declaration = ResolvedTypeRef(
      id: const QualifiedTypeId(namespace: "test", name: "Box"),
      revision: 1,
    );
    final exact = declaration.withArguments(const [StringType()]);
    final target = declaration.withArguments(const [ParameterType("T")]);

    await tester.pumpTestApp(
      child: EditorProtocolRenderer(
        envelope: TypedValueEnvelope(
          rootType: exact,
          rootValue: const StringValue("value"),
        ),
        typeCatalog: receivedRealmCatalog([
          TypeDefinition(
            id: declaration,
            kind: NominalTypeKind.concrete,
            representation: const ParameterType("T"),
            parameters: const [TypeParameter(name: "T")],
            defaultPresentationId: presentationId,
          ),
        ]),
        presentations: [
          PresentationDefinition.single(
            id: presentationId,
            target: NamedType(target),
            root: const PresentationNode(
              id: "generic",
              element: TypedFieldElement(
                binding: _rootBinding,
                expectedType: ParameterType("T"),
              ),
            ),
          ),
        ],
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text("value"), findsOneWidget);
  });

  testWidgets("localizes recursive default delegation", (tester) async {
    const id = PresentationId(namespace: "test", name: "recursive");
    final root = ResolvedTypeRef(
      id: const QualifiedTypeId(namespace: "test", name: "Recursive"),
      revision: 1,
    );
    final node = const PresentationNode(
      id: "recursive",
      element: DefaultPresentationElement(
        binding: _rootBinding,
        presentationId: id,
      ),
    );

    await tester.pumpTestApp(
      child: EditorProtocolRenderer(
        envelope: TypedValueEnvelope(
          rootType: root,
          rootValue: const StringValue("value"),
        ),
        typeCatalog: receivedRealmCatalog([
          TypeDefinition(
            id: root,
            kind: NominalTypeKind.concrete,
            representation: const StringType(),
            defaultPresentationId: id,
          ),
        ]),
        presentations: [
          PresentationDefinition.single(
            id: id,
            target: NamedType(root),
            root: node,
          ),
        ],
      ),
    );

    expect(find.text("Presentation delegation is recursive"), findsOneWidget);
  });

  testWidgets("renders independent map key and value presentations", (
    tester,
  ) async {
    final presentation = PresentationNode(
      id: "map",
      element: MapInputElement(
        control: const BoundControl(binding: _rootBinding),
        keyPresentation: const PresentationNode(
          id: "key",
          element: TextInputElement(
            control: BoundControl(
              binding: BindingReference(bindingId: BindingId(1)),
            ),
            multiline: false,
          ),
        ),
        valuePresentation: const PresentationNode(
          id: "value",
          element: TextElement(
            TypedExpression(
              resultType: StringType(),
              expression: BindingExpression(
                BindingReference(bindingId: BindingId(2)),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpTestApp(
      child: _renderer(
        type: const MapType(key: StringType(), value: StringType()),
        value: MapValue(const [
          DataMapEntry(
            key: StringValue("old key"),
            value: StringValue("rendered value"),
          ),
        ]),
        presentation: presentation,
      ),
    );

    await tester.tap(find.text("old key"));
    await tester.pumpAndSettle();
    expect(find.text("rendered value"), findsOneWidget);
    final keyField = find.byType(TextField);
    expect(tester.widget<TextField>(keyField).controller?.text, "old key");

    await tester.enterText(keyField, "new key");
    await tester.pumpAndSettle();

    final updatedKeyField = find.byType(TextField);
    expect(
      tester.widget<TextField>(updatedKeyField).controller?.text,
      "new key",
    );
    expect(
      tester.widget<TextField>(updatedKeyField).focusNode?.hasFocus,
      isTrue,
    );
    expect(find.text("rendered value"), findsOneWidget);
  });

  testWidgets(
    "uses the concrete default presentation inside a polymorphic input",
    (tester) async {
      const presentationId = PresentationId(
        namespace: "typewriter.core",
        name: "icon.iconify.default",
      );
      await tester.pumpTestApp(
        child: EditorProtocolRenderer(
          envelope: TypedValueEnvelope(
            rootType: standardTypeRefs.icon,
            rootValue: PolymorphicValue(
              concreteType: standardTypeRefs.iconifyIcon,
              value: RecordValue({"value": const StringValue("mdi:account")}),
            ),
          ),
          typeCatalog: receivedRealmCatalog(),
          presentations: [
            PresentationDefinition.single(
              id: presentationId,
              target: NamedType(standardTypeRefs.iconifyIcon),
              root: PresentationNode(
                id: "iconify",
                element: TextInputElement(
                  control: BoundControl(
                    binding: _rootBinding.at(DataPath.root.field("value")),
                  ),
                  multiline: false,
                ),
              ),
            ),
          ],
          presentation: PresentationNode(
            id: "icon",
            element: PolymorphicInputElement(
              control: const BoundControl(binding: _rootBinding),
              concreteTypes: [
                ConcreteTypePresentation(
                  type: standardTypeRefs.iconifyIcon,
                  label: "Iconify".asStringLiteral,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text("mdi:account"), findsOneWidget);
    },
  );
}

const _rootBinding = BindingReference(bindingId: BindingId(0));

EditorProtocolRenderer _renderer({
  required TypeExpression type,
  required DataValue value,
  required PresentationNode presentation,
}) {
  final root = ResolvedTypeRef(
    id: const QualifiedTypeId(namespace: "test", name: "root"),
    revision: 1,
  );
  return EditorProtocolRenderer(
    envelope: TypedValueEnvelope(rootType: root, rootValue: value),
    typeCatalog: receivedRealmCatalog([
      TypeDefinition(
        id: root,
        kind: NominalTypeKind.concrete,
        representation: type,
      ),
    ]),
    presentation: presentation,
  );
}
