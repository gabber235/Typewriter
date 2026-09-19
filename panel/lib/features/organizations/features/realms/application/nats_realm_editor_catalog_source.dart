import "package:freezed_annotation/freezed_annotation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "nats_realm_editor_catalog_source.freezed.dart";

/// NATS implementation of the realm editor catalog boundary.
///
/// This adapter owns wire serialization and decoding only. It translates
/// catalog fetches and invalidation watches into domain results, preserving
/// generation mismatches and decode diagnostics for [RealmEditorCatalogCache]
/// to coordinate. It does not cache definitions or decide when to refresh.
final class NatsRealmEditorCatalogSource implements RealmEditorCatalogSource {
  const NatsRealmEditorCatalogSource(this.ref);

  final Ref ref;

  @override
  Future<RealmEditorCatalogFetchResult> fetch(
    RealmEditorCatalogRoute route,
    RealmEditorCatalogRequest catalogRequest, {
    CatalogGeneration? expectedGeneration,
  }) async {
    final encoded = catalogRequest._encodeWire();
    if (encoded.valueOrNull == null) {
      return RealmEditorCatalogFetchUnavailable(encoded.diagnostics);
    }
    final request = skir.CatalogFetchRequest(
      expectedGeneration: expectedGeneration == null
          ? null
          : skir.CatalogGeneration(value: expectedGeneration.value),
      requestedTypes: encoded.valueOrNull!.$1,
      presentationIds: encoded.valueOrNull!.$2,
      subtypeQueries: encoded.valueOrNull!.$3,
    );
    final response = await ref.requestSkir(
      route.fetchSubject,
      skir.CatalogFetchRequest.serializer.toBytes(request),
      skir.CatalogFetchResult.serializer,
    );
    return response._decodeDomain();
  }

  @override
  Stream<RealmEditorCatalogWatchEvent> watchInvalidations(
    RealmEditorCatalogRoute route,
  ) {
    final request = skir.WatchEditorCatalogRequest();
    return ref.watchRequest(
      subject: route.invalidationRequestSubject,
      listenSubject: route.invalidationSubject,
      requestBytes: skir.WatchEditorCatalogRequest.serializer.toBytes(request),
      serializer: skir.CatalogWatchUpdate.serializer,
      transformer: (previous, response) => response._decodeDomain(),
    );
  }
}

extension on Iterable<skir.ElementCatalogEntry> {
  TypeResult<Map<String, RealmElementCatalogEntry>> _decodeDomain(
    TypeCatalog catalog,
  ) {
    final registry = TypeRegistry(catalog);
    final codec = SkirTypeCodec(registry);
    final entries = <String, RealmElementCatalogEntry>{};
    for (final entry in this) {
      final decodedType = codec.decodeReference(entry.descriptor.type);
      final type = decodedType.valueOrNull;
      if (type == null) {
        return TypeResult.failure(decodedType.diagnostics);
      }
      if (registry.resolveExact(type).valueOrNull == null) {
        return TypeResult.failure([
          realmEditorCatalogUnavailableDiagnostic(
            "Realm protocol inconsistency: element type '$type' is absent from the authoritative catalog",
          ),
        ]);
      }
      final id = entry.descriptor.elementTypeId.value.value;
      if (type.id != DeclaredTypeId(id)) {
        return TypeResult.failure([
          realmEditorCatalogUnavailableDiagnostic(
            "Element descriptor identity does not match its structural type",
          ),
        ]);
      }

      final eligibility = entry.eligibility._decodeDomain();
      entries[id] = RealmElementCatalogEntry(
        originArtifactId: entry.originArtifactId,
        sourcePart: entry.sourcePart,
        definition: DiscoveredElementDefinition(
          id: id,
          type: type,
          name: entry.descriptor.name,
          description: entry.descriptor.description,
          icon: entry.descriptor.icon._decodeDomain(),
          color: entry.descriptor.color.toFlutterColor(),
          availability: entry.descriptor.availability._decodeDomain(),
        ),
        eligible: eligibility.$1,
        available: entry.available,
        ineligibilityReasons: eligibility.$2,
      );
    }
    return TypeResult.success(entries);
  }
}

extension on Iterable<skir.PageCatalogEntry> {
  TypeResult<Map<PageKindRef, RealmPageDefinition>> _decodeDomain(
    TypeCatalog catalog,
  ) {
    final codec = SkirTypeCodec(TypeRegistry(catalog));
    final definitions = <PageKindRef, RealmPageDefinition>{};
    for (final entry in this) {
      final editor = entry.descriptor.editor._decodeDomain(codec);
      if (editor == null) {
        return TypeResult.failure([
          realmEditorCatalogUnavailableDiagnostic(
            "Realm returned an invalid page editor definition",
          ),
        ]);
      }
      final kind = PageKindRef.fromSkir(entry.descriptor.kind);
      definitions[kind] = RealmPageDefinition(
        kind: kind,
        name: entry.descriptor.name,
        description: entry.descriptor.description,
        icon: entry.descriptor.icon._decodeDomain(),
        color: entry.descriptor.color.toFlutterColor(),
        editor: editor,
        authoringRules: [
          for (final rule in entry.descriptor.authoringRules)
            RealmPageAuthoringRuleRef(
              id: rule.id,
              revision: rule.revision,
              configuration: rule.configuration,
            ),
        ],
        originArtifactId: entry.originArtifactId,
        sourcePart: entry.sourcePart,
      );
    }
    return TypeResult.success(definitions);
  }
}

extension on skir.Icon {
  IconValue _decodeDomain() => switch (this) {
    skir.Icon_iconifyWrapper(:final value) => IconValue.iconify(value),
    skir.Icon_svgWrapper(:final value) => IconValue.svg(value),
    skir.Icon_unknown() => throw StateError("Unknown icon"),
  };
}

extension on skir.PageEditorDefinition {
  RealmPageEditor? _decodeDomain(SkirTypeCodec codec) {
    switch (this) {
      case skir.PageEditorDefinition_graphWrapper(:final value):
        final nodes = value.nodeTypes._decodeReferences(codec);
        if (nodes == null) return null;
        return RealmGraphPageEditor(
          direction: switch (value.direction) {
            skir.GraphDirection.leftToRight => GraphDirection.leftToRight,
            skir.GraphDirection.rightToLeft => GraphDirection.rightToLeft,
            skir.GraphDirection.topToBottom => GraphDirection.topToBottom,
            skir.GraphDirection.bottomToTop => GraphDirection.bottomToTop,
            _ => throw StateError("Unknown graph direction"),
          },
          nodeTypes: nodes,
        );
      case skir.PageEditorDefinition_timelineWrapper(:final value):
        final tracks = value.trackTypes._decodeReferences(codec);
        final segments = value.segmentTypes._decodeReferences(codec);
        final keyframes = value.keyframeTypes._decodeReferences(codec);
        if (tracks == null || segments == null || keyframes == null) {
          return null;
        }
        return RealmTimelinePageEditor(
          trackTypes: tracks,
          segmentTypes: segments,
          keyframeTypes: keyframes,
        );
      case skir.PageEditorDefinition_unknown():
        return null;
    }
  }
}

extension on Iterable<skir.ResolvedTypeRef> {
  List<ResolvedTypeRef>? _decodeReferences(SkirTypeCodec codec) {
    final decoded = map(codec.decodeReference).toList();
    if (decoded.any((result) => result.valueOrNull == null)) return null;
    return decoded.map((result) => result.valueOrNull!).toList();
  }
}

extension on skir.ElementEligibility {
  (bool, List<String>) _decodeDomain() => switch (this) {
    skir.ElementEligibility_eligibleWrapper() => (true, const []),
    skir.ElementEligibility_ineligibleWrapper(:final value) => (
      false,
      value.reasons.toList(),
    ),
    skir.ElementEligibility_unknown() => (false, const ["Unknown eligibility"]),
  };
}

extension on skir.AvailabilityExpression {
  ElementAvailability _decodeDomain() => switch (this) {
    skir.AvailabilityExpression_alwaysWrapper() =>
      const ElementAvailability.always(),
    skir.AvailabilityExpression_factWrapper(:final value) =>
      ElementAvailability.fact(key: value.key, expected: value.expected),
    skir.AvailabilityExpression_allWrapper(:final value) =>
      ElementAvailability.all(
        value.expressions.map((item) => item._decodeDomain()).toList(),
      ),
    skir.AvailabilityExpression_anyWrapper(:final value) =>
      ElementAvailability.any(
        value.expressions.map((item) => item._decodeDomain()).toList(),
      ),
    skir.AvailabilityExpression_notWrapper(:final value) =>
      ElementAvailability.not(value.expression._decodeDomain()),
    skir.AvailabilityExpression_unknown() => throw StateError(
      "Unknown element availability",
    ),
  };
}

extension on skir.CatalogFetchResult {
  RealmEditorCatalogFetchResult _decodeDomain() => switch (this) {
    skir.CatalogFetchResult_successWrapper(:final value) =>
      value._decodeDomain(),
    skir.CatalogFetchResult_generationMismatchWrapper(:final value) =>
      RealmEditorCatalogGenerationMismatch(
        CatalogGeneration(value.actualGeneration.value),
      ),
    skir.CatalogFetchResult_unavailableWrapper(:final value) =>
      RealmEditorCatalogFetchUnavailable(value._decodeDiagnostics()),
    skir.CatalogFetchResult_unknown() => RealmEditorCatalogFetchUnavailable([
      realmEditorCatalogUnavailableDiagnostic(
        "Realm returned an unknown editor catalog response",
      ),
    ]),
  };
}

extension on skir.CatalogFetchSuccess {
  RealmEditorCatalogFetchResult _decodeDomain() {
    final value = this;
    final decoded = value.typeDefinitions.decodeDefinitions();
    final catalog = decoded.valueOrNull;
    if (catalog == null) {
      return RealmEditorCatalogFetchUnavailable(decoded.diagnostics);
    }
    final decodedParts = value._decodeCatalogParts(catalog);
    final decodedElements = value.elementEntries._decodeDomain(catalog.catalog);

    final elements = decodedElements.valueOrNull;
    if (elements == null) {
      return RealmEditorCatalogFetchUnavailable(decodedElements.diagnostics);
    }
    final decodedPages = value.pageEntries._decodeDomain(catalog.catalog);
    final pages = decodedPages.valueOrNull;
    if (pages == null) {
      return RealmEditorCatalogFetchUnavailable(decodedPages.diagnostics);
    }
    return RealmEditorCatalogFetched(
      RealmEditorCatalogSnapshot(
        catalog: catalog.catalog,
        generation: CatalogGeneration(value.generation.value),
        presentations: decodedParts.presentations,
        conversions: decodedParts.conversions,
        capabilities: decodedParts.capabilities,
        subtypeResults: decodedParts.subtypeResults,
        diagnostics: decodedParts.diagnostics,
        elements: elements,
        pageCatalog: RealmPageCatalog(
          definitions: pages,
          diagnostics: value.pageDiagnostics
              .map(
                (diagnostic) => RealmPageDiagnostic(
                  code: diagnostic.code,
                  message: diagnostic.message,
                  originArtifactId: diagnostic.originArtifactId,
                  sourcePart: diagnostic.sourcePart,
                  declarationName: diagnostic.declarationName,
                  kind: diagnostic.kind == null
                      ? null
                      : PageKindRef.fromSkir(diagnostic.kind!),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

extension on skir.CatalogWatchUpdate {
  RealmEditorCatalogWatchEvent _decodeDomain() => switch (this) {
    skir.CatalogWatchUpdate_initialWrapper(:final value) =>
      RealmEditorCatalogInvalidated(CatalogGeneration(value.value)),
    skir.CatalogWatchUpdate_invalidatedWrapper(:final value) =>
      RealmEditorCatalogInvalidated(CatalogGeneration(value.generation.value)),
    skir.CatalogWatchUpdate_unknown() => RealmEditorCatalogWatchUnavailable([
      realmEditorCatalogUnavailableDiagnostic(
        "Realm returned an unknown editor catalog invalidation",
      ),
    ]),
  };
}

extension on RealmEditorCatalogRequest {
  TypeResult<
    (
      List<skir.ResolvedTypeRef>,
      List<skir.PresentationId>,
      List<skir.SubtypeQuery>,
    )
  >
  _encodeWire() {
    final types = SkirTypeCodec(TypeRegistry(TypeCatalog([])));
    final encodedTypes = this.types.map(types.encodeReference).toList();
    final encodedQueries = subtypeQueries
        .map((query) => types.encodeReference(query.target))
        .toList();
    final diagnostics = [
      ...encodedTypes.expand((result) => result.diagnostics),
      ...encodedQueries.expand((result) => result.diagnostics),
    ];
    if (diagnostics.isNotEmpty) return TypeResult.failure(diagnostics);
    return TypeResult.success((
      encodedTypes.map((result) => result.valueOrNull!).toList(),
      [
        for (final id in presentations)
          skir.PresentationId(namespace: id.namespace, name: id.name),
      ],
      [
        for (final entry in subtypeQueries.indexed)
          skir.SubtypeQuery(
            queryId: skir.SubtypeQueryId(value: entry.$2.id),
            target: encodedQueries[entry.$1].valueOrNull!,
          ),
      ],
    ));
  }
}

extension on skir.CatalogFetchSuccess {
  _DecodedCatalogParts _decodeCatalogParts(DecodedTypeCatalog catalog) {
    final value = this;
    final editor = SkirEditorCodec(catalog.registry);
    final expressionDecoder = SkirExpressionDecoder(
      editor.typeCodec,
      editor.valueCodec,
    );
    final actionDecoder = SkirActionDecoder(
      expressionDecoder,
      editor.valueCodec,
    );
    final presentationDecoder = SkirPresentationDecoder(
      expressionDecoder,
      actionDecoder,
      editor.typeCodec,
    );
    final expressionEncoder = SkirExpressionEncoder(
      editor.typeCodec,
      editor.valueCodec,
    );

    final actionEncoder = SkirActionEncoder(
      expressionEncoder,
      editor.valueCodec,
    );
    final definitionCodec = SkirCatalogDefinitionCodec(
      types: editor.typeCodec,
      values: editor.valueCodec,
      presentations: presentationDecoder,
      presentationEncoder: SkirPresentationEncoder(
        expressionEncoder,
        actionEncoder,
        editor.typeCodec,
      ),
    );
    final conversionCodec = SkirConversionCodec(
      editor.typeCodec,
      editor.pathCodec,
    );

    final presentations = <PresentationId, PresentationDefinition>{};
    final conversions = <ConversionId, ConversionDefinition>{};
    final capabilities = <CapabilityId, CapabilityDefinition>{};
    final subtypeResults = <String, RealmEditorSubtypeResult>{};
    final diagnostics = value.diagnostics._decodeDiagnostics(
      registry: catalog.registry,
    );

    for (final item in value.presentationDefinitions) {
      final decoded = definitionCodec.decodePresentation(item);
      diagnostics.addAll(decoded.diagnostics);
      if (decoded.valueOrNull case final definition?) {
        presentations[definition.id] = definition;
      }
    }

    for (final item in value.conversions) {
      final decoded = conversionCodec.decode([item]);
      diagnostics.addAll(decoded.diagnostics);
      if (decoded.valueOrNull case [final definition]) {
        conversions[definition.id] = definition;
      }
    }

    for (final item in value.capabilityDefinitions) {
      final decoded = definitionCodec.decodeCapability(item);
      diagnostics.addAll(decoded.diagnostics);
      if (decoded.valueOrNull case final definition?) {
        capabilities[definition.id] = definition;
      }
    }

    for (final item in value.subtypeResults) {
      final matches = item.matchingTypes.map(editor.decodeType).toList();
      diagnostics.addAll(matches.expand((result) => result.diagnostics));
      final id = item.queryId.value;
      if (id.isEmpty || matches.any((result) => result.valueOrNull == null)) {
        continue;
      }
      subtypeResults[id] = RealmEditorSubtypeResult(
        queryId: id,
        matches: matches.map((result) => result.valueOrNull!).toList(),
      );
    }

    return _DecodedCatalogParts(
      presentations: presentations,
      conversions: conversions,
      capabilities: capabilities,
      subtypeResults: subtypeResults,
      diagnostics: diagnostics,
    );
  }
}

@freezed
abstract class _DecodedCatalogParts with _$DecodedCatalogParts {
  const factory _DecodedCatalogParts({
    required Map<PresentationId, PresentationDefinition> presentations,
    required Map<ConversionId, ConversionDefinition> conversions,
    required Map<CapabilityId, CapabilityDefinition> capabilities,
    required Map<String, RealmEditorSubtypeResult> subtypeResults,
    required List<TypeDiagnostic> diagnostics,
  }) = _DecodedCatalogPartsValue;
}

extension on Iterable<skir.TypeDiagnostic> {
  List<TypeDiagnostic> _decodeDiagnostics({TypeRegistry? registry}) {
    final codec = SkirEditorCodec(registry ?? TypeRegistry(TypeCatalog([])));
    return [for (final value in this) value.decodeWire(codec.pathCodec)];
  }
}
