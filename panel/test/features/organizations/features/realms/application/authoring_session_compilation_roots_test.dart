import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("matches every registered compilation projection by root type", () {
    final base = _type("11111111111111111111111111111111");
    final child = _type("22222222222222222222222222222222");
    final unrelated = _type("33333333333333333333333333333333");
    final catalog = TypeCatalog([
      TypeDefinition(id: base, kind: NominalTypeKind.openAbstract),
      TypeDefinition(
        id: child,
        kind: NominalTypeKind.concrete,
        parents: [base],
      ),
      TypeDefinition(id: unrelated, kind: NominalTypeKind.concrete),
    ]);
    final codec = SkirEditorCodec(TypeRegistry(catalog));
    final resource = skir.AuthoringResource(
      id: skir.ResourceId(value: "resource:child"),
      definition: ResourceDefinitionId("fixture.resource").toWire(),
      content: skir.TypedValueEnvelope(
        rootType: codec.encodeType(child).valueOrNull!,
        rootValue: codec.encodeValue(const UnitValue()).valueOrNull!,
      ),
    );
    final snapshot = RealmEditorCatalogSnapshot(
      catalog: catalog,
      generation: const CatalogGeneration("1"),
      compilationProjections: [
        RealmAuthoringCompilationProjection(
          id: "fixture.base",
          root: TypeExpression.named(base),
        ),
        RealmAuthoringCompilationProjection(
          id: "fixture.unrelated",
          root: TypeExpression.named(unrelated),
        ),
      ],
    );

    expect(snapshot.compilationRoots([resource]), {
      skir.CompilationRoot(
        projection: skir.CompilationProjectionId(value: "fixture.base"),
        resource: resource.id,
      ),
    });
  });
}

ResolvedTypeRef _type(String id) =>
    ResolvedTypeRef(id: DeclaredTypeId(id), revision: 1);
