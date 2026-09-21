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

  @override
  Future<RealmTypedValueInitializationResult> initialize(
    RealmEditorCatalogRoute route, {
    required CatalogGeneration generation,
    required TypedValueEnvelope partial,
    required TypeRegistry registry,
  }) async {
    final types = SkirTypeCodec(registry);
    final root = types.encodeReference(partial.rootType);
    final value = SkirDataValueCodec(types).encode(partial.rootValue);
    final diagnostics = [...root.diagnostics, ...value.diagnostics];
    if (diagnostics.isNotEmpty) {
      return RealmTypedValueInitializationRejected(diagnostics);
    }
    final request = skir.InitializeTypedValueRequest(
      generation: skir.CatalogGeneration(value: generation.value),
      rootType: root.valueOrNull!,
      partialValue: value.valueOrNull!,
    );
    final response = await ref.requestSkir(
      route.initializationSubject,
      skir.InitializeTypedValueRequest.serializer.toBytes(request),
      skir.InitializeTypedValueResult.serializer,
    );
    return switch (response) {
      skir.InitializeTypedValueResult_successWrapper(:final value) =>
        _decodeInitializedValue(value, types),
      skir.InitializeTypedValueResult_invalidWrapper(:final value) ||
      skir.InitializeTypedValueResult_unavailableWrapper(
        :final value,
      ) => RealmTypedValueInitializationRejected(
        value._decodeDiagnostics(registry: registry),
      ),
      skir.InitializeTypedValueResult_generationMismatchWrapper(:final value) =>
        RealmTypedValueInitializationGenerationMismatch(
          CatalogGeneration(value.actualGeneration.value),
        ),
      skir.InitializeTypedValueResult_unknown() =>
        RealmTypedValueInitializationRejected([
          realmEditorCatalogUnavailableDiagnostic(
            "Realm returned an unknown typed value initialization response",
          ),
        ]),
    };
  }
}

RealmTypedValueInitializationResult _decodeInitializedValue(
  skir.TypedValueEnvelope value,
  SkirTypeCodec types,
) {
  final root = types.decodeReference(value.rootType);
  final decoded = SkirDataValueCodec(types).decode(value.rootValue);
  final diagnostics = [...root.diagnostics, ...decoded.diagnostics];
  if (diagnostics.isNotEmpty) {
    return RealmTypedValueInitializationRejected(diagnostics);
  }
  return RealmTypedValueInitialized(
    TypedValueEnvelope(
      rootType: root.valueOrNull!,
      rootValue: decoded.valueOrNull!,
    ),
  );
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
      final presentationSubject = entry.presentationSubject._decodeDomain(
        registry,
      );
      if (presentationSubject.valueOrNull == null) {
        return TypeResult.failure(presentationSubject.diagnostics);
      }
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
        presentationSubject: presentationSubject.valueOrNull!,
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
    final registry = TypeRegistry(catalog);
    final codec = SkirTypeCodec(registry);
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
      final presentationSubject = entry.presentationSubject._decodeDomain(
        registry,
      );
      if (presentationSubject.valueOrNull == null) {
        return TypeResult.failure(presentationSubject.diagnostics);
      }
      definitions[kind] = RealmPageDefinition(
        kind: kind,
        name: entry.descriptor.name,
        description: entry.descriptor.description,
        icon: entry.descriptor.icon._decodeDomain(),
        color: entry.descriptor.color.toFlutterColor(),
        editor: editor,
        presentationSubject: presentationSubject.valueOrNull!,
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

extension on skir.CatalogPresentationSubject {
  TypeResult<TypedCatalogPresentationSubject> _decodeDomain(
    TypeRegistry registry,
  ) {
    final codec = SkirEditorCodec(registry);
    final target = codec.decodeType(this.target);
    final descriptorType = codec.decodeType(descriptor.rootType);
    final descriptorValue = codec.decodeValue(descriptor.rootValue);
    final identityType = codec.decodeType(identity.rootType);
    final identityValue = codec.decodeValue(identity.rootValue);
    final diagnostics = [
      ...target.diagnostics,
      ...descriptorType.diagnostics,
      ...descriptorValue.diagnostics,
      ...identityType.diagnostics,
      ...identityValue.diagnostics,
    ];
    if (diagnostics.isNotEmpty) return TypeResult.failure(diagnostics);
    return TypeResult.success((
      target: target.valueOrNull!,
      descriptor: TypedValueEnvelope(
        rootType: descriptorType.valueOrNull!,
        rootValue: descriptorValue.valueOrNull!,
      ),
      identity: TypedValueEnvelope(
        rootType: identityType.valueOrNull!,
        rootValue: identityValue.valueOrNull!,
      ),
    ));
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
    final resourceKinds = value.resourceKindDefinitions._decodeDomain(
      catalog.registry,
    );
    if (resourceKinds case TypeFailure(:final diagnostics)) {
      return RealmEditorCatalogFetchUnavailable(diagnostics);
    }
    final relations = value.relationDefinitions._decodeDomain(catalog.registry);
    if (relations case TypeFailure(:final diagnostics)) {
      return RealmEditorCatalogFetchUnavailable(diagnostics);
    }
    final collectionProjections = value.collectionProjectionDefinitions
        ._decodeDomain(catalog.registry);
    if (collectionProjections case TypeFailure(:final diagnostics)) {
      return RealmEditorCatalogFetchUnavailable(diagnostics);
    }
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
        resourceKinds: resourceKinds.valueOrNull!,
        relations: relations.valueOrNull!,
        collectionProjections: collectionProjections.valueOrNull!,
      ),
    );
  }
}

extension on Iterable<skir.CollectionProjectionDefinition> {
  TypeResult<
    Map<PresentationCollectionSourceId, RealmCollectionProjectionDefinition>
  >
  _decodeDomain(TypeRegistry registry) {
    final codec = SkirEditorCodec(registry);
    final result =
        <PresentationCollectionSourceId, RealmCollectionProjectionDefinition>{};
    final diagnostics = <TypeDiagnostic>[];
    for (final value in this) {
      final sourceId = PresentationCollectionSourceId(value.sourceId);
      final assignableWire = value.resources.assignableTo;
      final assignableTo = assignableWire == null
          ? null
          : codec.typeCodec.decodeExpression(assignableWire);
      final rowType = codec.typeCodec.decodeReference(value.rowType);
      final fields = value.fields
          .map((field) => field._decodeDomain(codec))
          .toList(growable: false);
      diagnostics
        ..addAll(assignableTo?.diagnostics ?? const [])
        ..addAll(rowType.diagnostics)
        ..addAll(fields.expand((field) => field.diagnostics));
      final kinds = value.resources.kinds.where((kind) {
        return kind == skir.ResourceKind.book ||
            kind == skir.ResourceKind.tag ||
            kind == skir.ResourceKind.page ||
            kind == skir.ResourceKind.element;
      }).toSet();
      if (value.sourceId.isEmpty ||
          result.containsKey(sourceId) ||
          kinds.length != value.resources.kinds.length ||
          (value.resources.assignableTo != null &&
              assignableTo?.valueOrNull == null) ||
          rowType.valueOrNull == null ||
          fields.any((field) => field.valueOrNull == null)) {
        diagnostics.add(
          realmEditorCatalogUnavailableDiagnostic(
            "Realm returned an invalid or duplicate collection projection",
          ),
        );
        continue;
      }
      result[sourceId] = RealmCollectionProjectionDefinition(
        sourceId: sourceId,
        kinds: kinds,
        assignableTo: assignableTo?.valueOrNull,
        rowType: rowType.valueOrNull!,
        fields: fields.map((field) => field.valueOrNull!).toList(),
      );
    }
    return diagnostics.isEmpty
        ? TypeResult.success(result)
        : TypeResult.failure(diagnostics);
  }
}

extension on skir.CollectionProjectionField {
  TypeResult<RealmCollectionProjectionField> _decodeDomain(
    SkirEditorCodec codec,
  ) {
    final target = codec.decodePath(this.target);
    final source = switch (this.source) {
      final skir.CollectionProjectionSource value
          when value == skir.CollectionProjectionSource.resourceId =>
        const TypeResult<RealmCollectionProjectionSource>.success(
          RealmCollectionResourceId(),
        ),
      skir.CollectionProjectionSource_contentWrapper(:final value) =>
        _mapCollectionProjectionSource(
          codec.decodePath(value),
          RealmCollectionContentPath.new,
        ),
      skir.CollectionProjectionSource_literalWrapper(:final value) =>
        _mapCollectionProjectionSource(
          codec.decodeValue(value),
          RealmCollectionLiteral.new,
        ),
      skir.CollectionProjectionSource_unknown() =>
        TypeResult<RealmCollectionProjectionSource>.failure([
          realmEditorCatalogUnavailableDiagnostic(
            "Realm returned an unknown collection projection source",
          ),
        ]),
      _ => TypeResult<RealmCollectionProjectionSource>.failure([
        realmEditorCatalogUnavailableDiagnostic(
          "Realm returned an invalid collection projection source",
        ),
      ]),
    };
    final diagnostics = [...target.diagnostics, ...source.diagnostics];
    if (target.valueOrNull == null || source.valueOrNull == null) {
      return TypeResult.failure(diagnostics);
    }
    return TypeResult.success(
      RealmCollectionProjectionField(
        target: target.valueOrNull!,
        source: source.valueOrNull!,
      ),
    );
  }
}

TypeResult<RealmCollectionProjectionSource> _mapCollectionProjectionSource<T>(
  TypeResult<T> result,
  RealmCollectionProjectionSource Function(T value) transform,
) => switch (result) {
  TypeSuccess(:final value) => TypeResult.success(transform(value)),
  TypeFailure(:final diagnostics) => TypeResult.failure(diagnostics),
};

extension on Iterable<skir.RelationDefinition> {
  TypeResult<Map<String, RealmRelationDefinition>> _decodeDomain(
    TypeRegistry registry,
  ) {
    final codec = SkirEditorCodec(registry);
    final result = <String, RealmRelationDefinition>{};
    final diagnostics = <TypeDiagnostic>[];
    for (final value in this) {
      final source = codec.decodeType(value.source);
      final target = codec.decodeType(value.target);
      final sourceEndpoint = value.sourceEndpoint?._decodeDomain(codec);
      final targetEndpoint = value.targetEndpoint?._decodeDomain(codec);
      diagnostics
        ..addAll(source.diagnostics)
        ..addAll(target.diagnostics)
        ..addAll(sourceEndpoint?.diagnostics ?? const [])
        ..addAll(targetEndpoint?.diagnostics ?? const []);
      final sourcePolicy = value.onSourceDelete._decodeDomain;
      final targetPolicy = value.onTargetDelete._decodeDomain;
      if (value.id.value.isEmpty ||
          result.containsKey(value.id.value) ||
          source.valueOrNull == null ||
          target.valueOrNull == null ||
          sourcePolicy == null ||
          targetPolicy == null ||
          (value.sourceEndpoint != null &&
              sourceEndpoint?.valueOrNull == null) ||
          (value.targetEndpoint != null &&
              targetEndpoint?.valueOrNull == null)) {
        diagnostics.add(
          realmEditorCatalogUnavailableDiagnostic(
            "Realm returned an invalid or duplicate relation definition",
          ),
        );
        continue;
      }
      result[value.id.value] = RealmRelationDefinition(
        id: value.id.value,
        source: source.valueOrNull!,
        target: target.valueOrNull!,
        onSourceDelete: sourcePolicy,
        onTargetDelete: targetPolicy,
        sourceEndpoint: sourceEndpoint?.valueOrNull,
        targetEndpoint: targetEndpoint?.valueOrNull,
      );
    }
    return diagnostics.isEmpty
        ? TypeResult.success(result)
        : TypeResult.failure(diagnostics);
  }
}

extension on skir.RelationEndpointDefinition {
  TypeResult<RealmRelationEndpointDefinition> _decodeDomain(
    SkirEditorCodec codec,
  ) {
    final owner = codec.decodeType(this.owner);
    final path = codec.decodePath(this.path);
    final side = switch (this.side) {
      skir.RelationEndpointSide.source => RealmRelationEndpointSide.source,
      skir.RelationEndpointSide.target => RealmRelationEndpointSide.target,
      _ => null,
    };
    final cardinality = switch (this.cardinality) {
      skir.RelationCardinality.one => RealmRelationCardinality.one,
      skir.RelationCardinality.many => RealmRelationCardinality.many,
      _ => null,
    };
    final diagnostics = [...owner.diagnostics, ...path.diagnostics];
    if (owner.valueOrNull == null ||
        path.valueOrNull == null ||
        side == null ||
        cardinality == null) {
      return TypeResult.failure([
        ...diagnostics,
        realmEditorCatalogUnavailableDiagnostic(
          "Realm returned an invalid relation endpoint definition",
        ),
      ]);
    }
    return TypeResult.success(
      RealmRelationEndpointDefinition(
        owner: owner.valueOrNull!,
        path: path.valueOrNull!,
        side: side,
        cardinality: cardinality,
      ),
    );
  }
}

extension on skir.RelationDeletePolicy {
  RealmRelationDeletePolicy? get _decodeDomain => switch (this) {
    skir.RelationDeletePolicy.restrict => RealmRelationDeletePolicy.restrict,
    skir.RelationDeletePolicy.cascade => RealmRelationDeletePolicy.cascade,
    skir.RelationDeletePolicy.clear => RealmRelationDeletePolicy.clear,
    _ => null,
  };
}

extension on Iterable<skir.ResourceKindDefinition> {
  TypeResult<Map<skir.ResourceKind, RealmResourceKindDefinition>> _decodeDomain(
    TypeRegistry registry,
  ) {
    final codec = SkirTypeCodec(registry);
    final result = <skir.ResourceKind, RealmResourceKindDefinition>{};
    final diagnostics = <TypeDiagnostic>[];
    for (final value in this) {
      final kind = switch (value.kind) {
        skir.ResourceKind.book ||
        skir.ResourceKind.tag ||
        skir.ResourceKind.page ||
        skir.ResourceKind.element => value.kind,
        _ => null,
      };
      final accepted = codec.decodeExpression(value.acceptedRoot);
      final defaultRoot = value.defaultRoot == null
          ? null
          : codec.decodeReference(value.defaultRoot);
      diagnostics.addAll(accepted.diagnostics);
      if (defaultRoot != null) diagnostics.addAll(defaultRoot.diagnostics);
      if (kind == null ||
          accepted.valueOrNull == null ||
          (value.defaultRoot != null && defaultRoot?.valueOrNull == null) ||
          result.containsKey(kind)) {
        diagnostics.add(
          realmEditorCatalogUnavailableDiagnostic(
            "Realm returned an invalid or duplicate resource kind definition",
          ),
        );
        continue;
      }
      result[kind] = RealmResourceKindDefinition(
        kind: kind,
        acceptedRoot: accepted.valueOrNull!,
        defaultRoot: defaultRoot?.valueOrNull,
      );
    }
    return diagnostics.isEmpty
        ? TypeResult.success(result)
        : TypeResult.failure(diagnostics);
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
