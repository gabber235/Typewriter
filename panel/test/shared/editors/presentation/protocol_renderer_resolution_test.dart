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
        typeCatalog: TypeCatalog([
          TypeDefinition(
            id: declaration,
            kind: NominalTypeKind.concrete,
            representation: const ParameterType("T"),
            parameters: const [TypeParameter(name: "T")],
            defaultPresentationId: presentationId,
          ),
        ]),
        presentations: [
          PresentationDefinition(
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

  testWidgets("selects the named single line string presentation", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: _renderer(
        type: const StringType(),
        value: const StringValue("single line"),
        presentation: const PresentationNode(
          id: "delegate",
          element: DefaultPresentationElement(
            binding: _rootBinding,
            presentationId: builtinStringSingleLinePresentationId,
          ),
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.minLines, 1);
    expect(field.maxLines, 1);
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
        typeCatalog: TypeCatalog([
          TypeDefinition(
            id: root,
            kind: NominalTypeKind.concrete,
            representation: const StringType(),
            defaultPresentationId: id,
          ),
        ]),
        presentations: [
          PresentationDefinition(id: id, target: NamedType(root), root: node),
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

  testWidgets("uses the standard icon default presentation", (tester) async {
    await tester.pumpTestApp(
      child: EditorProtocolRenderer(
        envelope: TypedValueEnvelope(
          rootType: standardTypeRefs.iconifyIcon,
          rootValue: const StringValue("mdi:sword"),
        ),
        typeCatalog: TypeCatalog(const []),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, "mdi:sword");
    expect(field.maxLines, 1);
  });
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
    typeCatalog: TypeCatalog([
      TypeDefinition(
        id: root,
        kind: NominalTypeKind.concrete,
        representation: type,
      ),
    ]),
    presentation: presentation,
  );
}
