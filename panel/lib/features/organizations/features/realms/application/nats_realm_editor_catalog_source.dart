import "package:freezed_annotation/freezed_annotation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/catalog.dart"
    as wire_catalog;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/diagnostic.dart"
    as wire_diagnostic;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/element_catalog.dart"
    as wire_element;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as wire_type;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/kernel/v1/icon.dart"
    as wire_icon;
import "package:typewriter_panel/typewriter_panel.dart";

part "nats_realm_editor_catalog_source.freezed.dart";

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
    final request = wire_catalog.CatalogFetchRequest(
      expectedGeneration: expectedGeneration == null
          ? null
          : wire_catalog.CatalogGeneration(value: expectedGeneration.value),
      requestedTypes: encoded.valueOrNull!.$1,
      presentationIds: encoded.valueOrNull!.$2,
      conversionIds: encoded.valueOrNull!.$3,
      realmActionIds: encoded.valueOrNull!.$4,
      subtypeQueries: encoded.valueOrNull!.$5,
    );
    final response = await ref.requestSkir(
      route.fetchSubject,
      wire_catalog.CatalogFetchRequest.serializer.toBytes(request),
      wire_catalog.CatalogFetchResult.serializer,
    );
    final decoded = response._decodeDomain();
    if (decoded case RealmEditorCatalogFetched(:final snapshot)) {
      return _fetchElements(route, snapshot);
    }
    return decoded;
  }

  Future<RealmEditorCatalogFetchResult> _fetchElements(
    RealmEditorCatalogRoute route,
    RealmEditorCatalogSnapshot snapshot,
  ) async {
    final request = wire_element.ElementCatalogRequest(
      expectedGeneration: wire_catalog.CatalogGeneration(
        value: snapshot.generation.value,
      ),
    );
    final response = await ref.requestSkir(
      route.elementsFetchSubject,
      wire_element.ElementCatalogRequest.serializer.toBytes(request),
      wire_element.ElementCatalogResult.serializer,
    );
    return response._decodeDomain(snapshot);
  }

  @override
  Stream<RealmEditorCatalogWatchEvent> watchInvalidations(
    RealmEditorCatalogRoute route,
  ) {
    final request = wire_catalog.WatchEditorCatalogRequest();
    return ref.watchRequest(
      subject: route.invalidationRequestSubject,
      listenSubject: route.invalidationSubject,
      requestBytes: wire_catalog.WatchEditorCatalogRequest.serializer.toBytes(
        request,
      ),
      serializer: wire_catalog.CatalogWatchUpdate.serializer,
      transformer: (previous, response) => response._decodeDomain(),
    );
  }
}

extension on wire_element.ElementCatalogResult {
  RealmEditorCatalogFetchResult _decodeDomain(
    RealmEditorCatalogSnapshot snapshot,
  ) => switch (this) {
    wire_element.ElementCatalogResult_successWrapper(:final value) =>
      value._decodeDomain(snapshot),
    wire_element.ElementCatalogResult_generationMismatchWrapper(:final value) =>
      RealmEditorCatalogGenerationMismatch(CatalogGeneration(value.value)),
    wire_element.ElementCatalogResult_unavailableWrapper(:final value) =>
      RealmEditorCatalogFetchUnavailable([
        realmEditorCatalogUnavailableDiagnostic(value.join("; ")),
      ]),
    wire_element.ElementCatalogResult_unknown() =>
      RealmEditorCatalogFetchUnavailable([
        realmEditorCatalogUnavailableDiagnostic(
          "Realm returned an unknown element catalog response",
        ),
      ]),
  };
}

extension on wire_element.ElementCatalogSuccess {
  RealmEditorCatalogFetchResult _decodeDomain(
    RealmEditorCatalogSnapshot snapshot,
  ) {
    if (generation.value != snapshot.generation.value) {
      return RealmEditorCatalogGenerationMismatch(
        CatalogGeneration(generation.value),
      );
    }
    final registry = TypeRegistry(snapshot.catalog);
    final codec = SkirTypeCodec(registry);
    final entries = <String, RealmElementCatalogEntry>{};
    for (final entry in this.entries) {
      final decodedType = codec.decodeReference(entry.descriptor.type);
      final type = decodedType.valueOrNull;
      if (type == null) {
        return RealmEditorCatalogFetchUnavailable(decodedType.diagnostics);
      }
      if (registry.resolveExact(type).valueOrNull == null) {
        return RealmEditorCatalogFetchUnavailable([
          realmEditorCatalogUnavailableDiagnostic(
            "Realm protocol inconsistency: element type '$type' is absent from the authoritative catalog",
          ),
        ]);
      }
      final id = entry.descriptor.elementTypeId.value.value;
      if (type.id != DeclaredTypeId(id)) {
        return RealmEditorCatalogFetchUnavailable([
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
          kind: switch (entry.descriptor.kind) {
            wire_element.ElementKind.entry => ElementKind.entry,
            wire_element.ElementKind.cue => ElementKind.cue,
            _ => throw StateError("Unknown element kind"),
          },
          type: type,
          name: entry.descriptor.name,
          description: entry.descriptor.description,
          icon: switch (entry.descriptor.icon) {
            wire_icon.Icon_iconifyWrapper(:final value) => IconValue.iconify(
              value,
            ),
            wire_icon.Icon_svgWrapper(:final value) => IconValue.svg(value),
            _ => throw StateError("Unknown element icon"),
          },
          color: entry.descriptor.color.toFlutterColor(),
          availability: entry.descriptor.availability._decodeDomain(),
        ),
        eligible: eligibility.$1,
        available: entry.available,
        ineligibilityReasons: eligibility.$2,
      );
    }
    return RealmEditorCatalogFetched(snapshot.copyWith(elements: entries));
  }
}

extension on wire_element.ElementEligibility {
  (bool, List<String>) _decodeDomain() => switch (this) {
    wire_element.ElementEligibility_eligibleWrapper() => (true, const []),
    wire_element.ElementEligibility_ineligibleWrapper(:final value) => (
      false,
      value.reasons.toList(),
    ),
    wire_element.ElementEligibility_unknown() => (
      false,
      const ["Unknown eligibility"],
    ),
  };
}

extension on wire_element.AvailabilityExpression {
  ElementAvailability _decodeDomain() => switch (this) {
    wire_element.AvailabilityExpression_alwaysWrapper() =>
      const ElementAvailability.always(),
    wire_element.AvailabilityExpression_factWrapper(:final value) =>
      ElementAvailability.fact(key: value.key, expected: value.expected),
    wire_element.AvailabilityExpression_allWrapper(:final value) =>
      ElementAvailability.all(
        value.expressions.map((item) => item._decodeDomain()).toList(),
      ),
    wire_element.AvailabilityExpression_anyWrapper(:final value) =>
      ElementAvailability.any(
        value.expressions.map((item) => item._decodeDomain()).toList(),
      ),
    wire_element.AvailabilityExpression_notWrapper(:final value) =>
      ElementAvailability.not(value.expression._decodeDomain()),
    wire_element.AvailabilityExpression_unknown() => throw StateError(
      "Unknown element availability",
    ),
  };
}

extension on wire_catalog.CatalogFetchResult {
  RealmEditorCatalogFetchResult _decodeDomain() => switch (this) {
    wire_catalog.CatalogFetchResult_successWrapper(:final value) =>
      value._decodeDomain(),
    wire_catalog.CatalogFetchResult_generationMismatchWrapper(:final value) =>
      RealmEditorCatalogGenerationMismatch(
        CatalogGeneration(value.actualGeneration.value),
      ),
    wire_catalog.CatalogFetchResult_unavailableWrapper(:final value) =>
      RealmEditorCatalogFetchUnavailable(value._decodeDiagnostics()),
    wire_catalog.CatalogFetchResult_unknown() =>
      RealmEditorCatalogFetchUnavailable([
        realmEditorCatalogUnavailableDiagnostic(
          "Realm returned an unknown editor catalog response",
        ),
      ]),
  };
}

extension on wire_catalog.CatalogFetchSuccess {
  RealmEditorCatalogFetchResult _decodeDomain() {
    final value = this;
    final decoded = value.typeDefinitions.decodeDefinitions();
    final catalog = decoded.valueOrNull;
    if (catalog == null) {
      return RealmEditorCatalogFetchUnavailable(decoded.diagnostics);
    }
    final decodedParts = value._decodeCatalogParts(catalog);
    return RealmEditorCatalogFetched(
      RealmEditorCatalogSnapshot(
        catalog: catalog.catalog,
        generation: CatalogGeneration(value.generation.value),
        presentations: decodedParts.presentations,
        conversions: decodedParts.conversions,
        realmActions: decodedParts.realmActions,
        subtypeResults: decodedParts.subtypeResults,
        diagnostics: decodedParts.diagnostics,
      ),
    );
  }
}

extension on wire_catalog.CatalogWatchUpdate {
  RealmEditorCatalogWatchEvent _decodeDomain() => switch (this) {
    wire_catalog.CatalogWatchUpdate_initialWrapper(:final value) =>
      RealmEditorCatalogInvalidated(CatalogGeneration(value.value)),
    wire_catalog.CatalogWatchUpdate_invalidatedWrapper(:final value) =>
      RealmEditorCatalogInvalidated(CatalogGeneration(value.generation.value)),
    wire_catalog.CatalogWatchUpdate_unknown() =>
      RealmEditorCatalogWatchUnavailable([
        realmEditorCatalogUnavailableDiagnostic(
          "Realm returned an unknown editor catalog invalidation",
        ),
      ]),
  };
}

extension on RealmEditorCatalogRequest {
  TypeResult<
    (
      List<wire_type.ResolvedTypeRef>,
      List<wire_type.PresentationId>,
      List<wire_type.ConversionId>,
      List<wire_type.RealmActionId>,
      List<wire_catalog.SubtypeQuery>,
    )
  >
  _encodeWire() {
    final types = SkirTypeCodec(TypeRegistry(TypeCatalog([])));
    final encodedTypes = this.types.map(types.encodeReference).toList();
    final encodedQueries = subtypeQueries
        .map((query) => types.encodeReference(query.target))
        .toList();
    final encodedConversions = conversions
        .map((id) => id.encodeWire())
        .toList();
    final diagnostics = [
      ...encodedTypes.expand((result) => result.diagnostics),
      ...encodedQueries.expand((result) => result.diagnostics),
      ...encodedConversions.expand((result) => result.diagnostics),
    ];
    if (diagnostics.isNotEmpty) return TypeResult.failure(diagnostics);
    return TypeResult.success((
      encodedTypes.map((result) => result.valueOrNull!).toList(),
      [
        for (final id in presentations)
          wire_type.PresentationId(namespace: id.namespace, name: id.name),
      ],
      encodedConversions.map((result) => result.valueOrNull!).toList(),
      [
        for (final id in realmActions)
          wire_type.RealmActionId(namespace: id.namespace, name: id.name),
      ],
      [
        for (final entry in subtypeQueries.indexed)
          wire_catalog.SubtypeQuery(
            queryId: wire_catalog.SubtypeQueryId(value: entry.$2.id),
            target: encodedQueries[entry.$1].valueOrNull!,
          ),
      ],
    ));
  }
}

extension on wire_catalog.CatalogFetchSuccess {
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
    final actions = <RealmActionId, RealmActionDefinition>{};
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
    for (final item in value.realmActionDefinitions) {
      final decoded = definitionCodec.decodeRealmAction(item);
      diagnostics.addAll(decoded.diagnostics);
      if (decoded.valueOrNull case final definition?) {
        actions[definition.id] = definition;
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
      realmActions: actions,
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
    required Map<RealmActionId, RealmActionDefinition> realmActions,
    required Map<String, RealmEditorSubtypeResult> subtypeResults,
    required List<TypeDiagnostic> diagnostics,
  }) = _DecodedCatalogPartsValue;
}

extension on Iterable<wire_diagnostic.TypeDiagnostic> {
  List<TypeDiagnostic> _decodeDiagnostics({TypeRegistry? registry}) {
    final codec = SkirEditorCodec(registry ?? TypeRegistry(TypeCatalog([])));
    return [for (final value in this) value.decodeWire(codec.pathCodec)];
  }
}
