import "dart:async";

import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

const authoringBookSearchResultType = SearchResultType(
  id: "authoring.book",
  rowRendererId: "authoring.book",
  label: "Book",
);
const authoringTagSearchResultType = SearchResultType(
  id: "authoring.tag",
  rowRendererId: "authoring.tag",
  label: "Tag",
);
const authoringPageSearchResultType = SearchResultType(
  id: "authoring.page",
  rowRendererId: "authoring.page",
  label: "Page",
);
const authoringElementSearchResultType = SearchResultType(
  id: "authoring.element",
  rowRendererId: "authoring.element",
  label: "Element",
);

const authoringBookSearchSelector = KeyValueSelectorDefinition(
  id: "book",
  key: "book:",
  value: QuerySelectorValue.sourceBacked(),
);
const authoringPageSearchSelector = KeyValueSelectorDefinition(
  id: "page",
  key: "page:",
  value: QuerySelectorValue.sourceBacked(),
);
const authoringTagSearchSelector = KeyValueSelectorDefinition(
  id: "tag",
  key: "tag:",
  value: QuerySelectorValue.sourceBacked(),
);
const authoringTypeSearchSelector = KeyValueSelectorDefinition(
  id: "type",
  key: "type:",
  value: QuerySelectorValue.sourceBacked(),
);

const authoringSearchSelectors = <QuerySelectorDefinition>[
  authoringBookSearchSelector,
  authoringPageSearchSelector,
  authoringTagSearchSelector,
  authoringTypeSearchSelector,
];

enum AuthoringSearchResultKind { book, tag, page, element }

final class AuthoringSearchResultPayload {
  const AuthoringSearchResultPayload({
    required this.subject,
    required this.context,
    required this.presentation,
    required this.kind,
  });

  final TypedPresentationSubject subject;
  final TypedValueEnvelope context;
  final SubjectPresentationModel presentation;
  final AuthoringSearchResultKind kind;

  skir.ResourceId get id => subject.identity.id;
  skir.ResourceId? get owner => subject.identity.owner;

  skir.ResourceId? contextReference(String field) =>
      switch (context.rootValue) {
        RecordValue(:final fields) when fields[field] is ReferenceValue =>
          (fields[field]! as ReferenceValue).id,
        _ => null,
      };

  PageKindRef? get pageKind {
    final content = subject.content.rootValue;
    if (content is! RecordValue || content.fields["kind"] is! RecordValue) {
      return null;
    }
    final fields = (content.fields["kind"]! as RecordValue).fields;
    final id = fields["id"];
    final revision = fields["revision"];
    return id is StringValue && revision is IntegerValue
        ? PageKindRef(id: id.value, revision: revision.value.toInt())
        : null;
  }
}

final class RealmAuthoringSearchSource
    implements SearchSource, SearchSelectorCompletionSource {
  RealmAuthoringSearchSource({
    required this.ref,
    required this.organizationId,
    required this.realmId,
    this.contextPage,
    this.referenceTarget,
    this.referenceOrigins = const [],
    this.typeRegistry,
  });

  final Ref ref;
  final skir.RecordId organizationId;
  final skir.RecordId realmId;
  final skir.ResourceId? contextPage;
  final ResolvedTypeRef? referenceTarget;
  final List<skir.ResourceId> referenceOrigins;
  final TypeRegistry? typeRegistry;

  final _snapshots = StreamController<SearchSourceSnapshot>.broadcast(
    sync: true,
  );
  var _revision = 0;
  var _disposed = false;

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  List<QuerySelectorDefinition> get selectors =>
      referenceTarget == null ? authoringSearchSelectors : const [];

  @override
  void initialize(SearchQueryContext context) => search(context);

  @override
  void search(SearchQueryContext context) {
    if (_disposed) return;
    final revision = ++_revision;
    _snapshots.add(SearchSourceSnapshot.loading());
    unawaited(_search(context, revision));
  }

  Future<void> _search(SearchQueryContext context, int revision) async {
    try {
      final catalog = _catalog();
      final query = encodeRealmSearchQuery(context);
      final target = _encodedTarget(catalog);
      final response = await ref.requestSkir(
        RealmServiceAddress(
          organizationId: organizationId,
          realmId: realmId,
        ).request("library.authoring.graph.search"),
        skir.SearchAuthoringGraphRequest.serializer.toBytes(
          skir.SearchAuthoringGraphRequest(
            generation: skir.CatalogGeneration(value: catalog.generation.value),
            query: query,
            resources: skir.ResourceFilter(
              kinds: const [],
              assignableTo: target,
            ),
            scope: _scope(target),
            referenceTarget: target,
            facets: _validationFacets(query),
          ),
        ),
        skir.SearchAuthoringGraphResponse.serializer,
      );
      if (_disposed || revision != _revision) return;
      await _publish(response, revision);
    } on Object catch (error) {
      if (_disposed || revision != _revision) return;
      _publishError(["Realm search failed: $error"]);
    }
  }

  RealmEditorCatalogSnapshot _catalog() {
    final snapshot = ref.read(realmEditorCatalogProvider).value?.snapshot;
    if (snapshot == null) {
      throw StateError("Realm search catalog is unavailable");
    }
    return snapshot;
  }

  skir.TypeExpression? _encodedTarget(RealmEditorCatalogSnapshot catalog) {
    final target = referenceTarget;
    if (target == null) return null;
    final registry = typeRegistry ?? TypeRegistry(catalog.catalog);
    final encoded = SkirTypeCodec(registry).encodeExpression(NamedType(target));
    if (encoded.valueOrNull == null) {
      throw StateError(
        encoded.diagnostics.map((item) => item.message).join(", "),
      );
    }
    return encoded.valueOrNull;
  }

  skir.GraphSelection? _scope(skir.TypeExpression? target) {
    final seeds = referenceOrigins.isNotEmpty
        ? referenceOrigins
        : contextPage == null
        ? const <skir.ResourceId>[]
        : [contextPage!];
    if (seeds.isEmpty) return null;
    return skir.GraphSelection(
      key: "search.scope",
      seed: skir.ResourceSeed.createIds(
        values: seeds,
        requireAssignableTo: null,
      ),
      steps: [
        skir.RelationStep(
          relations: skir.RelationFilter.any,
          direction: skir.RelationDirection.both,
          minDepth: 1,
          maxDepth: contextPage == null ? 1 : 2,
          target: target == null
              ? null
              : skir.ResourceFilter(kinds: const [], assignableTo: target),
        ),
      ],
    );
  }

  List<skir.SearchFacetRequest> _validationFacets(skir.RealmSearchQuery query) {
    final values = <String, List<String>>{};
    for (final selector in query.selectors) {
      final value = selector.value;
      if (value != null) {
        values.putIfAbsent(selector.selectorId, () => []).add(value);
      }
    }
    return [
      for (final entry in values.entries)
        skir.SearchFacetRequest(
          facetId: skir.SearchFacetId(value: entry.key),
          partial: null,
          validate: entry.value,
        ),
    ];
  }

  Future<void> _publish(
    skir.SearchAuthoringGraphResponse response,
    int revision,
  ) async {
    switch (response) {
      case skir.SearchAuthoringGraphResponse_successWrapper(:final value):
        final catalogResult = await _catalogForSearch(value);
        if (_disposed || revision != _revision) return;
        final snapshot = switch (catalogResult) {
          RealmEditorCatalogFetched(:final snapshot) => snapshot,
          _ => null,
        };
        if (snapshot == null) {
          _publishError(["Realm search catalog generation is unavailable"]);
          return;
        }
        final decoded = value.hits
            .map((hit) => _result(hit, snapshot))
            .toList(growable: false);
        _snapshots.add(
          SearchSourceSnapshot.ready(
            nodes: decoded
                .map((item) => item.result)
                .nonNulls
                .map((result) => SearchNode.result(result: result))
                .toList(growable: false),
            errorSummaries: [
              for (final item in decoded.indexed)
                for (final diagnostic in item.$2.diagnostics)
                  SearchErrorSummary(
                    id: "realm.authoring.decode.${item.$1}.${diagnostic.code.name}",
                    message: diagnostic.message,
                    severity: SearchErrorSeverity.error,
                    sourceLabel: "Realm",
                  ),
            ],
            selectorValidations: [
              for (final facet in value.facets)
                for (final accepted in facet.accepted)
                  SearchSelectorValidation(
                    selectorId: facet.facetId.value,
                    value: accepted,
                    status: SearchSelectorValidationStatus.accepted,
                  ),
              for (final facet in value.facets)
                for (final rejected in facet.rejected)
                  SearchSelectorValidation(
                    selectorId: facet.facetId.value,
                    value: rejected,
                    status: SearchSelectorValidationStatus.rejected,
                  ),
            ],
          ),
        );
      case skir.SearchAuthoringGraphResponse_invalidWrapper(:final value):
        _publishError(value.diagnostics.map((item) => item.message).toList());
      case skir.SearchAuthoringGraphResponse_catalogChangedWrapper():
        _publishError(const ["The Realm editor catalog changed"]);
      case skir.SearchAuthoringGraphResponse_internalErrorWrapper():
        _publishError(const ["Realm could not complete the search"]);
      case skir.SearchAuthoringGraphResponse_unknown():
        _publishError(const ["Realm returned an unknown search response"]);
    }
  }

  Future<RealmEditorCatalogFetchResult> _catalogForSearch(
    skir.AuthoringSearchSnapshot search,
  ) async {
    final request = presentationSubjectCatalogRequest(
      search.hits.map((hit) => hit.subject),
      contexts: search.hits.map((hit) => hit.context),
    );
    final demand = request.valueOrNull;
    if (demand == null) {
      return RealmEditorCatalogFetchResult.unavailable(request.diagnostics);
    }
    final cache = ref.read(realmEditorCatalogCacheProvider);
    if (cache == null) {
      return RealmEditorCatalogFetchResult.unavailable([
        realmEditorCatalogUnavailableDiagnostic(
          "Realm search catalog is unavailable",
        ),
      ]);
    }
    return cache.fetchExact(CatalogGeneration(search.generation.value), demand);
  }

  ({SearchResult? result, List<TypeDiagnostic> diagnostics}) _result(
    skir.AuthoringSearchHit hit,
    RealmEditorCatalogSnapshot snapshot,
  ) {
    final codec = TypedAuthoringCodec(snapshot);
    final subjectResult = codec.decodeSubject(hit.subject);
    final contextResult = codec.decodeEnvelope(hit.context);
    final subject = subjectResult.valueOrNull;
    final context = contextResult.valueOrNull;
    if (subject == null || context == null) {
      return (
        result: null,
        diagnostics: [
          ...subjectResult.diagnostics,
          ...contextResult.diagnostics,
        ],
      );
    }
    final target = referenceTarget;
    if (target != null &&
        !NamedType(subject.content.rootType)
            .isStructurallyAssignableTo(NamedType(target), codec.registry)) {
      return (result: null, diagnostics: const []);
    }
    return target == null
        ? _authoringResult(subject, context, snapshot, codec)
        : _referenceResult(subject, codec);
  }

  ({SearchResult? result, List<TypeDiagnostic> diagnostics}) _authoringResult(
    TypedPresentationSubject subject,
    TypedValueEnvelope context,
    RealmEditorCatalogSnapshot snapshot,
    TypedAuthoringCodec codec,
  ) {
    final kind = _resultKind(subject.content.rootType);
    final presentationResult = codec.subjectPresentation(
      subject,
      PresentationRole.authoringResult,
      context: context,
    );
    final presentation =
        presentationResult.valueOrNull ??
        (
          model: PresentationModel(
            catalog: snapshot.catalog,
            inputs: const {},
            root: PresentationNode(
              id: "authoring.search.diagnostic",
              element: DiagnosticElement(presentationResult.diagnostics),
            ),
            diagnostics: presentationResult.diagnostics,
          ),
          presentation: const PresentationId(
            namespace: "typewriter.diagnostic",
            name: "authoring.search",
          ),
        );
    return (
      result: SearchResult(
        id: "${kind.name}:${subject.identity.id.value}",
        type: switch (kind) {
          AuthoringSearchResultKind.book => authoringBookSearchResultType,
          AuthoringSearchResultKind.tag => authoringTagSearchResultType,
          AuthoringSearchResultKind.page => authoringPageSearchResultType,
          AuthoringSearchResultKind.element => authoringElementSearchResultType,
        },
        payload: AuthoringSearchResultPayload(
          subject: subject,
          context: context,
          presentation: presentation,
          kind: kind,
        ),
        title: subject.identity.id.value,
      ),
      diagnostics: const [],
    );
  }

  ({SearchResult? result, List<TypeDiagnostic> diagnostics}) _referenceResult(
    TypedPresentationSubject subject,
    TypedAuthoringCodec codec,
  ) {
    final presentationResult = codec.subjectPresentation(
      subject,
      PresentationRole.referenceOption,
    );
    final presentation = presentationResult.valueOrNull;
    if (presentation == null) {
      return (result: null, diagnostics: presentationResult.diagnostics);
    }
    final bindings = <BindingId, BindingSource>{};
    for (final MapEntry(key: id, value: input)
        in presentation.model.inputs.entries) {
      if (input case PresentationValueInput(:final type, :final value)) {
        bindings[id] = EditorValueBindingSource(
          type: type,
          value: value,
          revision: 0,
        );
      }
    }
    return (
      result: SearchResult(
        id: "reference:${subject.identity.id.value}",
        type: presentationSearchResultType,
        title: subject.identity.id.value,
        payload: PresentationSearchResultPayload(
          selectedValue: ReferenceValue(subject.identity.id),
          providerKey: "authoring.reference",
          expressions: ExpressionContext(
            bindings: BindingEnvironment(bindings),
          ),
          presentation: presentation.model.root,
        ),
      ),
      diagnostics: const [],
    );
  }

  void _publishError(List<String> messages) {
    _snapshots.add(
      SearchSourceSnapshot.error(
        errorSummaries: [
          for (final item in messages.indexed)
            SearchErrorSummary(
              id: "realm.authoring.response.${item.$1}",
              message: item.$2,
              severity: SearchErrorSeverity.error,
              sourceLabel: "Realm",
            ),
        ],
      ),
    );
  }

  @override
  Future<SearchPreviewRequestResult> preview(SearchPreviewRequest request) {
    throw UnimplementedError();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _revision++;
    unawaited(_snapshots.close());
  }

  @override
  Future<SearchSelectorCompletionResult> completeSelector(
    SearchSelectorCompletionRequest request,
  ) async {
    if (!authoringSearchSelectors.any(
      (item) => item.id == request.selectorId,
    )) {
      return const SearchSelectorCompletionResult();
    }
    final catalog = _catalog();
    final target = _encodedTarget(catalog);
    final response = await ref.requestSkir(
      RealmServiceAddress(
        organizationId: organizationId,
        realmId: realmId,
      ).request("library.authoring.graph.search"),
      skir.SearchAuthoringGraphRequest.serializer.toBytes(
        skir.SearchAuthoringGraphRequest(
          generation: skir.CatalogGeneration(value: catalog.generation.value),
          query: skir.RealmSearchQuery(
            normalizedQuery: "",
            selectors: const [],
            selectorExpression: request.scope == null
                ? null
                : encodeRealmSearchSelectorExpression(request.scope!),
            terms: const [],
          ),
          resources: skir.ResourceFilter(kinds: const [], assignableTo: target),
          scope: _scope(target),
          referenceTarget: target,
          facets: [
            skir.SearchFacetRequest(
              facetId: skir.SearchFacetId(value: request.selectorId),
              partial: request.partial,
              validate: const [],
            ),
          ],
        ),
      ),
      skir.SearchAuthoringGraphResponse.serializer,
    );
    return switch (response) {
      skir.SearchAuthoringGraphResponse_successWrapper(:final value) =>
        SearchSelectorCompletionResult(
          values: value.facets.firstOrNull?.suggestions.toList() ?? const [],
          exhaustive: true,
        ),
      skir.SearchAuthoringGraphResponse_invalidWrapper(:final value) =>
        throw StateError(
          value.diagnostics.map((item) => item.message).join(", "),
        ),
      skir.SearchAuthoringGraphResponse_catalogChangedWrapper() =>
        throw StateError("The Realm editor catalog changed"),
      skir.SearchAuthoringGraphResponse_internalErrorWrapper() =>
        throw StateError("Realm could not suggest selector values"),
      skir.SearchAuthoringGraphResponse_unknown() => throw StateError(
        "Realm returned an unknown search response",
      ),
    };
  }
}

AuthoringSearchResultKind _resultKind(ResolvedTypeRef type) =>
    switch (type.id) {
      QualifiedTypeId(namespace: "com.typewritermc.library", name: "Book") =>
        AuthoringSearchResultKind.book,
      QualifiedTypeId(namespace: "com.typewritermc.library", name: "Tag") =>
        AuthoringSearchResultKind.tag,
      QualifiedTypeId(namespace: "com.typewritermc.library", name: "Page") =>
        AuthoringSearchResultKind.page,
      _ => AuthoringSearchResultKind.element,
    };

Future<List<ReferenceResourceSummary>> resolveAuthoringReferences({
  required Ref ref,
  required skir.RecordId organizationId,
  required skir.RecordId realmId,
  required ResolvedTypeRef target,
  required List<skir.ResourceId> ids,
  required TypeRegistry registry,
}) async {
  if (ids.isEmpty) return const [];
  final encodedTarget = SkirTypeCodec(registry)
      .encodeExpression(NamedType(target));
  if (encodedTarget.valueOrNull == null) {
    throw StateError(
      encodedTarget.diagnostics.map((item) => item.message).join(", "),
    );
  }
  final catalog = ref.read(realmEditorCatalogProvider).value?.snapshot;
  if (catalog == null) {
    throw StateError("Realm reference catalog is unavailable");
  }
  final graph = await ref
      .read(resourceRepositoriesProvider)
      .authoring(organizationId, realmId)
      .fetch(
        skir.GraphSelection(
          key: "reference.resolve",
          seed: skir.ResourceSeed.createIds(
            values: ids,
            requireAssignableTo: encodedTarget.valueOrNull,
          ),
          steps: const [],
        ),
        generation: catalog.generation,
      );
  final subjects = {
    for (final value in graph.presentations) value.resource: value.subject,
  };
  final demand = presentationSubjectCatalogRequest(subjects.values);
  if (demand.valueOrNull == null) {
    throw StateError(demand.diagnostics.map((item) => item.message).join(", "));
  }
  final cache = ref.read(realmEditorCatalogCacheProvider);
  if (cache == null) throw StateError("Realm reference catalog is unavailable");
  final exact = await cache.fetchExact(
    CatalogGeneration(graph.generation.value),
    demand.valueOrNull!,
  );
  final snapshot = switch (exact) {
    RealmEditorCatalogFetched(:final snapshot) => snapshot,
    RealmEditorCatalogGenerationMismatch() => throw StateError(
      "Realm reference catalog generation is unavailable",
    ),
    RealmEditorCatalogFetchUnavailable(:final diagnostics) => throw StateError(
      diagnostics.firstOrNull?.message ??
          "Realm reference catalog is unavailable",
    ),
  };
  final selection = graph.selections.single;
  final missing = selection.missingIds.toSet();
  final incompatible = selection.incompatibleIds.toSet();
  final codec = TypedAuthoringCodec(snapshot);
  return [
    for (final id in ids)
      if (subjects[id] case final subject?)
        _resolvedReferenceSummary(id, subject, codec)
      else
        ReferenceResourceSummary(
          id: id,
          exists: false,
          title: id.value,
          subtitle: incompatible.contains(id)
              ? "Referenced resource has an incompatible type"
              : missing.contains(id)
              ? "Referenced resource is missing"
              : "Referenced resource is unavailable",
          diagnostics: [
            _searchResourceDiagnostic(
              id,
              incompatible.contains(id)
                  ? "Referenced resource has an incompatible type"
                  : missing.contains(id)
                  ? "Referenced resource is missing"
                  : "Referenced resource is unavailable",
            ),
          ],
        ),
  ];
}

ReferenceResourceSummary _resolvedReferenceSummary(
  skir.ResourceId id,
  skir.PresentationSubject wire,
  TypedAuthoringCodec codec,
) {
  final subject = codec.decodeSubject(wire);
  final decoded = subject.valueOrNull;
  if (decoded == null) {
    return ReferenceResourceSummary(
      id: id,
      exists: false,
      title: id.value,
      diagnostics: subject.diagnostics,
    );
  }
  final presentation = codec.subjectPresentation(
    decoded,
    PresentationRole.referenceSummary,
  );
  return ReferenceResourceSummary(
    id: id,
    exists: true,
    title: id.value,
    presentation: presentation.valueOrNull?.model,
    diagnostics: presentation.diagnostics,
  );
}

TypeDiagnostic _searchResourceDiagnostic(skir.ResourceId id, String message) =>
    TypeDiagnostic(
      code: TypeDiagnosticCode.invalidValue,
      message: "$message (${id.value})",
      pathPresent: false,
    );
