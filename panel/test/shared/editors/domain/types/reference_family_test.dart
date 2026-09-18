import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("reference family derives from nominal ancestry", () {
    final registry = TypeRegistry(
      TypeCatalog(referenceResourceTypes.definitions),
    );

    expect(
      registry.referenceFamily(referenceResourceTypes.book).valueOrNull,
      ReferenceFamily.book,
    );
    expect(
      registry.referenceFamily(referenceResourceTypes.pageKind).valueOrNull,
      ReferenceFamily.page,
    );
    expect(
      registry.referenceFamily(referenceResourceTypes.tag).valueOrNull,
      ReferenceFamily.tag,
    );
    expect(
      registry.referenceFamily(referenceResourceTypes.element).valueOrNull,
      ReferenceFamily.element,
    );
  });

  test("reference family rejects ambiguous ancestry", () {
    const ambiguous = ResolvedTypeRef(
      id: TypeId.qualified(namespace: "test", name: "Ambiguous"),
      revision: 1,
    );
    final registry = TypeRegistry(
      TypeCatalog([
        ...referenceResourceTypes.definitions,
        TypeDefinition(
          id: ambiguous,
          kind: NominalTypeKind.concrete,
          parents: [referenceResourceTypes.book, referenceResourceTypes.tag],
          representation: const UnitType(),
        ),
      ]),
    );

    final result = registry.referenceFamily(ambiguous);

    expect(result.valueOrNull, isNull);
    expect(
      result.diagnostics.single.message,
      contains("exactly one resource family"),
    );
  });
}
