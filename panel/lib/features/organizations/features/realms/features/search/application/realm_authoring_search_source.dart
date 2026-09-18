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
  final skir.RecordId? contextPage;
  final ResolvedTypeRef? referenceTarget;
  final List<skir.RecordId> referenceOrigins;
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
      final address = RealmServiceAddress(
        organizationId: organizationId,
        realmId: realmId,
      );
      final target = referenceTarget;
      final registry = typeRegistry;
      final encodedTarget = target == null || registry == null
          ? null
          : SkirTypeCodec(registry).encodeReference(target).valueOrNull;
      if (target != null && encodedTarget == null) {
        throw StateError("Reference target could not be encoded");
      }
      final response = await ref.requestSkir(
        address.request("library.authoring.content.search"),
        skir.SearchAuthoringContentRequest.serializer.toBytes(
          skir.SearchAuthoringContentRequest(
            query: encodeRealmSearchQuery(context),
            contextPage: contextPage,
            referenceScope: encodedTarget == null
                ? null
                : skir.ReferenceSearchScope(
                    origins: referenceOrigins,
                    target: encodedTarget,
                  ),
          ),
        ),
        skir.SearchAuthoringContentResponse.serializer,
      );
      if (_disposed || revision != _revision) return;
      _publish(response);
    } on Object catch (error) {
      if (_disposed || revision != _revision) return;
      _snapshots.add(
        SearchSourceSnapshot.error(
          errorSummaries: [
            SearchErrorSummary(
              id: "realm.authoring.transport",
              message: "Realm search failed: $error",
              severity: SearchErrorSeverity.error,
              sourceLabel: "Realm",
            ),
          ],
        ),
      );
    }
  }

  void _publish(skir.SearchAuthoringContentResponse response) {
    switch (response) {
      case skir.SearchAuthoringContentResponse_successWrapper(:final value):
        final hits = value.hits
            .map(_result)
            .nonNulls
            .map((hit) => SearchNode.result(result: hit))
            .toList(growable: false);

        _snapshots.add(
          SearchSourceSnapshot.ready(
            nodes: hits,
            selectorValidations: value.selectorValidations
                .map(
                  (validation) => SearchSelectorValidation(
                    selectorId: validation.selector.selectorId,
                    value: validation.value,
                    status: validation.accepted
                        ? SearchSelectorValidationStatus.accepted
                        : SearchSelectorValidationStatus.rejected,
                  ),
                )
                .toList(growable: false),
          ),
        );
      case skir.SearchAuthoringContentResponse_invalidWrapper(:final value):
        final messages = value.diagnostics
            .map((diagnostic) => diagnostic.message)
            .toList();
        _publishError(
          messages.isEmpty ? const ["Realm rejected the search"] : messages,
        );
      case skir.SearchAuthoringContentResponse_internalErrorWrapper():
        _publishError(const ["Realm could not complete the search"]);
      case skir.SearchAuthoringContentResponse_unknown():
        _publishError(const ["Realm returned an unknown search response"]);
    }
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

  SearchResult? _result(skir.AuthoringSearchHit hit) {
    if (referenceTarget != null) return _referenceResult(hit);
    return switch (hit) {
      skir.AuthoringSearchHit_bookWrapper(:final value) => SearchResult(
        id: "book:${value.id.toSurrealQl()}",
        type: authoringBookSearchResultType,
        payload: value,
        title: value.title,
      ),
      skir.AuthoringSearchHit_tagWrapper(:final value) => SearchResult(
        id: "tag:${value.id.toSurrealQl()}",
        type: authoringTagSearchResultType,
        payload: value,
        title: value.name,
      ),
      skir.AuthoringSearchHit_pageWrapper(:final value) => SearchResult(
        id: "page:${value.id.toSurrealQl()}",
        type: authoringPageSearchResultType,
        payload: value,
        title: value.name,
        subtitle: [
          value.chapter,
          value.book.title,
        ].where((part) => part.isNotEmpty).join(" / "),
      ),
      skir.AuthoringSearchHit_elementWrapper(:final value) => SearchResult(
        id: "element:${value.id.toSurrealQl()}",
        type: authoringElementSearchResultType,
        payload: value,
        title: value.name,
        subtitle: value.page.name,
      ),
      skir.AuthoringSearchHit_unknown() => null,
    };
  }

  SearchResult? _referenceResult(skir.AuthoringSearchHit hit) {
    final data = switch (hit) {
      skir.AuthoringSearchHit_bookWrapper(:final value) => (
        value.id,
        value.title,
        null,
      ),
      skir.AuthoringSearchHit_tagWrapper(:final value) => (
        value.id,
        value.name,
        null,
      ),
      skir.AuthoringSearchHit_pageWrapper(:final value) => (
        value.id,
        value.name,
        [
          value.chapter,
          value.book.title,
        ].where((part) => part.isNotEmpty).join(" / "),
      ),
      skir.AuthoringSearchHit_elementWrapper(:final value) => (
        value.id,
        value.name,
        value.page.name,
      ),
      skir.AuthoringSearchHit_unknown() => null,
    };
    if (data == null) return null;
    final subtitle = data.$3;
    return SearchResult(
      id: "reference:${data.$1.toSurrealQl()}",
      type: presentationSearchResultType,
      title: data.$2,
      subtitle: subtitle,
      payload: PresentationSearchResultPayload(
        selectedValue: ReferenceValue(data.$1),
        providerKey: "authoring.reference",
        expressions: const ExpressionContext(bindings: BindingEnvironment({})),
        presentation: PresentationNode(
          id: "authoring.reference.result",
          element: ColumnElement(
            spacing: 2,
            children: [
              PresentationNode(
                id: "authoring.reference.result.title",
                element: TextElement(data.$2.asStringLiteral),
              ),
              if (subtitle != null && subtitle.isNotEmpty)
                PresentationNode(
                  id: "authoring.reference.result.subtitle",
                  element: TextElement(subtitle.asStringLiteral),
                ),
            ],
          ),
        ),
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
    final kind = _selectorKinds[request.selectorId];
    if (kind == null) return const SearchSelectorCompletionResult();
    final address = RealmServiceAddress(
      organizationId: organizationId,
      realmId: realmId,
    );
    final response = await ref.requestSkir(
      address.request("library.authoring.selector.suggest"),
      skir.SuggestAuthoringSelectorValuesRequest.serializer.toBytes(
        skir.SuggestAuthoringSelectorValuesRequest(
          selector: kind,
          partial: request.partial,
          scope: request.scope == null
              ? null
              : encodeRealmSearchSelectorExpression(request.scope!),
          contextPage: contextPage,
        ),
      ),
      skir.SuggestAuthoringSelectorValuesResponse.serializer,
    );
    return switch (response) {
      skir.SuggestAuthoringSelectorValuesResponse_successWrapper(
        :final value,
      ) =>
        SearchSelectorCompletionResult(
          values: value.values.toList(growable: false),
          exhaustive: value.exhaustive,
        ),
      skir.SuggestAuthoringSelectorValuesResponse_invalidWrapper(
        :final value,
      ) =>
        throw StateError(
          value.diagnostics.map((item) => item.message).join(", "),
        ),
      skir.SuggestAuthoringSelectorValuesResponse_internalErrorWrapper() =>
        throw StateError("Realm could not suggest selector values"),
      skir.SuggestAuthoringSelectorValuesResponse_unknown() => throw StateError(
        "Realm returned an unknown selector response",
      ),
    };
  }
}

const _selectorKinds = <String, skir.AuthoringSelectorKind>{
  "book": skir.AuthoringSelectorKind.book,
  "page": skir.AuthoringSelectorKind.page,
  "tag": skir.AuthoringSelectorKind.tag,
  "type": skir.AuthoringSelectorKind.elementType,
};

Future<List<ReferenceResourceSummary>> resolveAuthoringReferences({
  required Ref ref,
  required skir.RecordId organizationId,
  required skir.RecordId realmId,
  required ResolvedTypeRef target,
  required List<skir.RecordId> ids,
  required TypeRegistry registry,
}) async {
  if (ids.isEmpty) return const [];
  final encodedTarget = SkirTypeCodec(registry).encodeReference(target);
  if (encodedTarget.valueOrNull == null) {
    throw StateError(
      encodedTarget.diagnostics.map((item) => item.message).join(", "),
    );
  }
  final address = RealmServiceAddress(
    organizationId: organizationId,
    realmId: realmId,
  );
  final response = await ref.requestSkir(
    address.request("library.authoring.resources.resolve"),
    skir.ResolveAuthoringResourcesRequest.serializer.toBytes(
      skir.ResolveAuthoringResourcesRequest(
        ids: ids,
        referenceTarget: encodedTarget.valueOrNull!,
      ),
    ),
    skir.ResolveAuthoringResourcesResponse.serializer,
  );
  return switch (response) {
    skir.ResolveAuthoringResourcesResponse_successWrapper(:final value) =>
      value.resources
          .map(
            (resource) => ReferenceResourceSummary(
              id: resource.id,
              exists: resource.exists,
              title: resource.title,
              subtitle: resource.subtitle,
            ),
          )
          .toList(growable: false),
    skir.ResolveAuthoringResourcesResponse_invalidWrapper(:final value) =>
      throw StateError(
        value.diagnostics.map((item) => item.message).join(", "),
      ),
    skir.ResolveAuthoringResourcesResponse_internalErrorWrapper() =>
      throw StateError("Realm could not resolve references"),
    skir.ResolveAuthoringResourcesResponse_unknown() => throw StateError(
      "Realm returned an unknown reference response",
    ),
  };
}

extension on skir.AuthoringSelectorKind {
  String get selectorId => switch (this) {
    skir.AuthoringSelectorKind.book => "book",
    skir.AuthoringSelectorKind.page => "page",
    skir.AuthoringSelectorKind.tag => "tag",
    skir.AuthoringSelectorKind.elementType => "type",
    skir.AuthoringSelectorKind_unknown() => "unknown",
  };
}
