import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  final catalog = CheckedEditorCatalog(
    (skir.EditorCatalogWireSnapshot.mutable()
          ..types = [
            skir.PublishedType(
              placementField: null,
              definition: skir.TypeDefinition(
                id: frameworkResourceIdUse.definition,
                parameters: const [],
                representation: skir.RepresentationTemplate.createScalar(
                  kind: skir.ScalarKind.text,
                ),
                parents: const [],
              ),
              status: skir.DeclarationStatus.ready,
              display: null,
              effectiveFields: const [],
              ancestorTemplates: const [],
            ),
          ])
        .toFrozen(),
  );
  final origin = skir.ExpressionBindingId(value: "context:test.origin");
  final type = skir.TypeUse.wrapNamed(frameworkResourceIdUse);
  final imports = [
    skir.PresentationContextInput(bindingId: origin, valueType: type),
  ];

  test("absent caller inputs retain their declared type and missing value", () {
    final normalized = <skir.ExpressionBindingId, PortableExpressionBinding>{}
        .withContextImports(catalog: catalog, imports: imports);
    expect(normalized[origin]?.value, skir.DataValue.unfilled);
    expect(
      normalized[origin]?.schema,
      CompletePortablePresentationBinding(type),
    );
    expect(normalized.clear, throwsUnsupportedError);
  });

  test(
    "caller inputs preserve canonical identity and reject malformed payloads",
    () {
      final supplied = skir.ResourceId(value: "book:current")
          .toExpressionBinding();
      final normalized = {origin: supplied}
          .withContextImports(catalog: catalog, imports: imports);
      expect(normalized[origin], same(supplied));
      expect(
        () => {
          origin: PortableExpressionBinding(
            value: skir.DataValue.wrapInteger("42"),
            schema: CompletePortablePresentationBinding(type),
          ),
        }.withContextImports(catalog: catalog, imports: imports),
        throwsFormatException,
      );
    },
  );

  test("caller inputs cannot supply an editable binding", () {
    final supplied = {
      origin: PortableExpressionBinding(
        value: skir.ResourceId(value: "book:current").toExpressionValue(),
        schema: CompletePortablePresentationBinding(type),
        location: skir.ValueLocation(
          resource: skir.ResourceId(value: "book:current"),
          path: editorRootPath,
        ),
      ),
    };
    expect(
      () => <skir.ExpressionBindingId, PortableExpressionBinding>{}
          .withCallerInputs(supplied),
      throwsStateError,
    );
  });

  test(
    "nested composition retains one supplier and rejects conflicting inputs",
    () {
      final supplied = skir.ResourceId(value: "book:current")
          .toExpressionBinding();
      final inherited = {origin: supplied}.withCallerInputs({origin: supplied});
      expect(inherited[origin], same(supplied));
      expect(
        () => inherited.withCallerInputs({
          origin: skir.ResourceId(value: "book:other").toExpressionBinding(),
        }),
        throwsStateError,
      );
    },
  );
}
