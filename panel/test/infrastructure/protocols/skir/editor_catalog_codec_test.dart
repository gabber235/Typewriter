import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/capability.dart"
    as wire_capability;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/presentation.dart"
    as wire_presentation;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as wire_type;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  final reference = ResolvedTypeRef(
    id: const QualifiedTypeId(namespace: "example", name: "entry"),
    revision: 1,
  );
  final catalog = TypeCatalog([
    TypeDefinition(
      id: reference,
      kind: NominalTypeKind.concrete,
      representation: RecordType(
        fields: const {"name": TypeField(name: "name", type: StringType())},
      ),
      defaultPresentationId: const PresentationId(
        namespace: "example",
        name: "main",
      ),
    ),
  ]);
  final types = SkirTypeCodec(TypeRegistry(catalog));
  final values = SkirDataValueCodec(types);
  final expressionEncoder = SkirExpressionEncoder(types, values);
  final expressionDecoder = SkirExpressionDecoder(types, values);
  final presentationEncoder = SkirPresentationEncoder(
    expressionEncoder,
    SkirActionEncoder(expressionEncoder, values),
    types,
  );
  final presentationDecoder = SkirPresentationDecoder(
    expressionDecoder,
    SkirActionDecoder(expressionDecoder, values),
    types,
  );
  final definitions = SkirCatalogDefinitionCodec(
    types: types,
    values: values,
    presentations: presentationDecoder,
    presentationEncoder: presentationEncoder,
  );

  test("maps all direct catalogue definition shapes and fields", () {
    final encodedCatalog = catalog.encodeWire().valueOrNull!;
    final encodedType = encodedCatalog.definitions.single;
    expect(encodedType.typeId.kind, wire_type.TypeId_kind.qualifiedWrapper);
    expect(encodedType.revision, 1);
    expect(
      encodedType.kind.kind,
      wire_type.TypeDefinitionKind_kind.concreteConst,
    );
    expect(
      encodedType.representation.kind,
      wire_type.TypeExpression_kind.recordWrapper,
    );
    expect(encodedType.defaultPresentationId?.namespace, "example");
    expect(encodedType.defaultPresentationId?.name, "main");
    expect(encodedCatalog.decodeDomain().valueOrNull!.catalog, catalog);

    final presentation = PresentationDefinition(
      id: const PresentationId(namespace: "example", name: "main"),
      target: NamedType(reference),
      root: const PresentationNode(id: "root", element: DividerElement()),
    );
    final encodedPresentation = definitions
        .encodePresentation(presentation)
        .valueOrNull!;
    expect(encodedPresentation.presentationId.namespace, "example");
    expect(encodedPresentation.presentationId.name, "main");
    expect(
      encodedPresentation.target.kind,
      wire_type.TypeExpression_kind.namedWrapper,
    );
    expect(encodedPresentation.root.nodeId, "root");
    expect(
      encodedPresentation.root.element?.kind,
      wire_presentation.PresentationElement_kind.dividerConst,
    );
    expect(
      definitions.decodePresentation(encodedPresentation).valueOrNull,
      presentation,
    );

    final capability = wire_capability.CapabilityDefinition.createComputation(
      capabilityId: wire_type.CapabilityId(value: "capability"),
      requestType: types.encodeReference(reference).valueOrNull!,
      resultType: types.encodeReference(reference).valueOrNull!,
    );
    expect(
      definitions.decodeCapability(capability).valueOrNull,
      CapabilityDefinition.computation(
        id: const CapabilityId("capability"),
        requestType: reference,
        resultType: reference,
      ),
    );

    final envelope = TypedValueEnvelope(
      rootType: reference,
      rootValue: RecordValue(const {"name": StringValue("Entry")}),
    );
    final encodedEnvelope = definitions.encodeEnvelope(envelope).valueOrNull!;
    expect(
      encodedEnvelope.rootType,
      types.encodeReference(reference).valueOrNull,
    );
    expect(
      encodedEnvelope.rootValue.kind,
      wire_type.TypedValue_kind.recordWrapper,
    );
    expect(definitions.decodeEnvelope(encodedEnvelope).valueOrNull, envelope);
  });
}
