import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/catalog.dart"
    as wire_catalog;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/diagnostic.dart"
    as wire_diagnostic;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/presentation.dart"
    as wire_presentation;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as wire_type;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/typed_value.dart"
    as wire_value;
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

  test("round trips all direct catalogue definition shapes", () {
    final encodedCatalog = catalog.encodeWire().valueOrNull!;
    final catalogBytes = wire_type.TypeCatalog.serializer.toBytes(
      encodedCatalog,
    );
    final decodedCatalog = wire_type.TypeCatalog.serializer
        .fromBytes(catalogBytes)
        .decodeDomain()
        .valueOrNull!;
    final reencodedCatalog = decodedCatalog.catalog.encodeWire().valueOrNull!;
    expect(
      wire_type.TypeCatalog.serializer.toBytes(reencodedCatalog),
      catalogBytes,
    );

    final presentation = PresentationDefinition(
      id: const PresentationId(namespace: "example", name: "main"),
      target: NamedType(reference),
      root: const PresentationNode(id: "root", element: DividerElement()),
    );
    final encodedPresentation = definitions
        .encodePresentation(presentation)
        .valueOrNull!;
    final presentationBytes = wire_presentation
        .PresentationDefinition
        .serializer
        .toBytes(encodedPresentation);
    final decodedPresentation = definitions
        .decodePresentation(
          wire_presentation.PresentationDefinition.serializer.fromBytes(
            presentationBytes,
          ),
        )
        .valueOrNull!;
    final reencodedPresentation = definitions
        .encodePresentation(decodedPresentation)
        .valueOrNull!;
    expect(
      wire_presentation.PresentationDefinition.serializer.toBytes(
        reencodedPresentation,
      ),
      presentationBytes,
    );

    final action = RealmActionDefinition(
      id: const RealmActionId(namespace: "example", name: "save"),
      payloadType: reference,
      resultType: reference,
    );
    final encodedAction = definitions.encodeRealmAction(action).valueOrNull!;
    final actionBytes = wire_catalog.RealmActionDefinition.serializer.toBytes(
      encodedAction,
    );
    final decodedAction = definitions
        .decodeRealmAction(
          wire_catalog.RealmActionDefinition.serializer.fromBytes(actionBytes),
        )
        .valueOrNull!;
    final reencodedAction = definitions
        .encodeRealmAction(decodedAction)
        .valueOrNull!;
    expect(
      wire_catalog.RealmActionDefinition.serializer.toBytes(reencodedAction),
      actionBytes,
    );

    final envelope = TypedValueEnvelope(
      rootType: reference,
      rootValue: RecordValue(const {"name": StringValue("Entry")}),
    );
    final encodedEnvelope = definitions.encodeEnvelope(envelope).valueOrNull!;
    final envelopeBytes = wire_value.TypedValueEnvelope.serializer.toBytes(
      encodedEnvelope,
    );
    final decodedEnvelope = definitions
        .decodeEnvelope(
          wire_value.TypedValueEnvelope.serializer.fromBytes(envelopeBytes),
        )
        .valueOrNull!;
    final reencodedEnvelope = definitions
        .encodeEnvelope(decodedEnvelope)
        .valueOrNull!;
    expect(
      wire_value.TypedValueEnvelope.serializer.toBytes(reencodedEnvelope),
      envelopeBytes,
    );
  });

  test("round trips fetch request and every fetch result variant", () {
    final wireReference = types.encodeReference(reference).valueOrNull!;
    final request = wire_catalog.CatalogFetchRequest(
      expectedGeneration: wire_catalog.CatalogGeneration(value: "generation-1"),
      requestedTypes: [wireReference],
      presentationIds: [
        wire_type.PresentationId(namespace: "example", name: "main"),
      ],
      conversionIds: [
        wire_type.ConversionId(namespace: "example", name: "convert"),
      ],
      realmActionIds: [
        wire_type.RealmActionId(namespace: "example", name: "save"),
      ],
      subtypeQueries: [
        wire_catalog.SubtypeQuery(
          queryId: wire_catalog.SubtypeQueryId(value: "query-1"),
          target: wireReference,
        ),
      ],
    );
    final requestBytes = wire_catalog.CatalogFetchRequest.serializer.toBytes(
      request,
    );
    expect(
      wire_catalog.CatalogFetchRequest.serializer.toBytes(
        wire_catalog.CatalogFetchRequest.serializer.fromBytes(requestBytes),
      ),
      requestBytes,
    );

    final diagnostic = wire_diagnostic.TypeDiagnostic(
      code: wire_diagnostic.DiagnosticCode.invalidPresentation,
      severity: wire_diagnostic.DiagnosticSeverity.error,
      message: "Unavailable",
      path: null,
      relatedType: null,
      details: const [],
    );
    final results = <wire_catalog.CatalogFetchResult>[
      wire_catalog.CatalogFetchResult.createSuccess(
        generation: wire_catalog.CatalogGeneration(value: "generation-2"),
        typeDefinitions: const [],
        presentationDefinitions: const [],
        conversions: const [],
        realmActionDefinitions: const [],
        subtypeResults: [
          wire_catalog.SubtypeResult(
            queryId: wire_catalog.SubtypeQueryId(value: "query-1"),
            matchingTypes: [wireReference],
          ),
        ],
        diagnostics: [diagnostic],
      ),
      wire_catalog.CatalogFetchResult.createGenerationMismatch(
        actualGeneration: wire_catalog.CatalogGeneration(value: "generation-3"),
      ),
      wire_catalog.CatalogFetchResult.wrapUnavailable([diagnostic]),
    ];
    for (final result in results) {
      final bytes = wire_catalog.CatalogFetchResult.serializer.toBytes(result);
      expect(
        wire_catalog.CatalogFetchResult.serializer.toBytes(
          wire_catalog.CatalogFetchResult.serializer.fromBytes(bytes),
        ),
        bytes,
      );
    }
  });

  test("round trips watch request, initial update, and invalidation", () {
    final request = wire_catalog.WatchEditorCatalogRequest();
    final requestBytes = wire_catalog.WatchEditorCatalogRequest.serializer
        .toBytes(request);
    expect(
      wire_catalog.WatchEditorCatalogRequest.serializer.toBytes(
        wire_catalog.WatchEditorCatalogRequest.serializer.fromBytes(
          requestBytes,
        ),
      ),
      requestBytes,
    );

    final invalidated = wire_catalog.CatalogInvalidated(
      generation: wire_catalog.CatalogGeneration(value: "generation-4"),
      reason: "changed",
    );
    final invalidationBytes = wire_catalog.CatalogInvalidated.serializer
        .toBytes(invalidated);
    expect(
      wire_catalog.CatalogInvalidated.serializer.toBytes(
        wire_catalog.CatalogInvalidated.serializer.fromBytes(invalidationBytes),
      ),
      invalidationBytes,
    );
    for (final update in <wire_catalog.CatalogWatchUpdate>[
      wire_catalog.CatalogWatchUpdate.createInitial(value: "generation-4"),
      wire_catalog.CatalogWatchUpdate.wrapInvalidated(invalidated),
    ]) {
      final bytes = wire_catalog.CatalogWatchUpdate.serializer.toBytes(update);
      expect(
        wire_catalog.CatalogWatchUpdate.serializer.toBytes(
          wire_catalog.CatalogWatchUpdate.serializer.fromBytes(bytes),
        ),
        bytes,
      );
    }
  });
}
