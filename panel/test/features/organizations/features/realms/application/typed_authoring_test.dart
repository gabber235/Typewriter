import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("decodes the declared ResourceIdentity carried by a subject", () {
    final identityType = ResolvedTypeRef(
      id: TypeId.declared("214fdb63564640e5bc15c7524f6121ef"),
      revision: 1,
    );
    final codec = TypedAuthoringCodec(
      RealmEditorCatalogSnapshot(
        catalog: panelPresentationTypeCatalog([
          TypeDefinition(
            id: identityType,
            kind: NominalTypeKind.concrete,
            representation: RecordType(
              fields: {
                "id": const TypeField(name: "id", type: StringType()),
                "owner": TypeField(
                  name: "owner",
                  type: NamedType(
                    standardTypeRefs.optionOf(const StringType()),
                  ),
                ),
              },
            ),
          ),
        ]),
        generation: const CatalogGeneration("test"),
      ),
    );
    final identity = TypedValueEnvelope(
      rootType: identityType,
      rootValue: RecordValue({
        "id": const StringValue("resource:book"),
        "owner": PolymorphicValue(
          concreteType: standardTypeRefs.noneOf(const StringType()),
          value: const UnitValue(),
        ),
      }),
    );
    final envelope = codec.encodeEnvelope(identity).valueOrNull!;
    final decoded = codec.decodeSubject(
      skir.PresentationSubject(
        content: envelope,
        descriptor: envelope,
        identity: envelope,
        resource: skir.ResourceId(value: "resource:book"),
        definition: skir.ResourceDefinitionId(value: "typewriter.book"),
        ownerPath: const [],
      ),
    );

    expect(decoded.diagnostics, isEmpty);
    expect(decoded.valueOrNull?.identity.id.value, "resource:book");
    expect(decoded.valueOrNull?.identity.owner, isNull);
  });
}
