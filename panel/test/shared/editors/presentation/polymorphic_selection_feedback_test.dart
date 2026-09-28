import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  const abstract = ResolvedTypeRef(
    id: TypeId.qualified(namespace: "selection", name: "Icon"),
    revision: 1,
  );
  const iconify = ResolvedTypeRef(
    id: TypeId.qualified(namespace: "selection", name: "Iconify"),
    revision: 1,
  );
  const svg = ResolvedTypeRef(
    id: TypeId.qualified(namespace: "selection", name: "Svg"),
    revision: 1,
  );
  final catalog = TypeCatalog(const [
    TypeDefinition(id: abstract, kind: NominalTypeKind.openAbstract),
    TypeDefinition(
      id: iconify,
      kind: NominalTypeKind.concrete,
      parents: [abstract],
      representation: RecordType(
        fields: {"value": TypeField(name: "value", type: StringType())},
      ),
    ),
    TypeDefinition(
      id: svg,
      kind: NominalTypeKind.concrete,
      parents: [abstract],
      representation: RecordType(
        fields: {"source": TypeField(name: "source", type: StringType())},
      ),
    ),
  ]);

  testWidgets(
    "keeps the committed type while selection is pending and shows failure",
    (tester) async {
      final pending = Completer<ConcreteTypeInitializationResult>();
      final owner = LocalEditor(
        rootType: const NamedType(abstract),
        typeCatalog: catalog,
        value: PolymorphicValue(
          concreteType: iconify,
          value: RecordValue({"value": const StringValue("mdi:book")}),
        ),
        concreteTypeInitializer: ({required type, required supplied}) =>
            pending.future,
      );
      addTearDown(owner.dispose);

      await tester.pumpTestApp(
        child: ComposedEditor(
          model: PresentationModel.editor(
            owner: owner,
            presentation: PresentationNode(
              id: "icon",
              element: PolymorphicInputElement(
                control: const BoundControl(
                  binding: BindingReference(bindingId: BindingId(0)),
                ),
                concreteTypes: [
                  ConcreteTypePresentation(
                    type: iconify,
                    label: "Iconify".asStringLiteral,
                  ),
                  ConcreteTypePresentation(
                    type: svg,
                    label: "Svg".asStringLiteral,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text("Svg"));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        (owner.value(DataPath.root).valueOrNull! as PolymorphicValue)
            .concreteType,
        iconify,
      );

      pending.complete(
        const ConcreteTypeInitializationRejected([
          TypeDiagnostic(
            code: TypeDiagnosticCode.invalidValue,
            message: "SVG unavailable",
          ),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.text("SVG unavailable"), findsOneWidget);
      expect(
        (owner.value(DataPath.root).valueOrNull! as PolymorphicValue)
            .concreteType,
        iconify,
      );
    },
  );
}
