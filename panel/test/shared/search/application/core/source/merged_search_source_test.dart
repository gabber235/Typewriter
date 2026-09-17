// ignore_for_file: cascade_invocations

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../support/search_core_test_harness.dart";

void main() {
  group("MergedSearchSource", () {
    test("initializes, searches, and disposes every child once", () {
      final first = FakeSearchSource(
        selectors: const [KeyValueSelectorDefinition(id: "tag", key: "tag:")],
      );
      final second = FakeSearchSource(
        selectors: const [
          KeyValueSelectorDefinition(id: "world", key: "world:"),
        ],
      );
      final source = [first, second].merged();

      source.initialize(SearchQueryContext.empty);
      source.search(queryContext("home"));
      source.dispose();
      source.dispose();

      expect(first.initializeCount, 1);
      expect(second.initializeCount, 1);
      expect(first.searches, [queryContext("home")]);
      expect(second.searches, [queryContext("home")]);
      expect(first.disposeCount, 1);
      expect(second.disposeCount, 1);
    });

    test("keeps partial results visible while another child loads", () {
      final first = FakeSearchSource();
      final second = FakeSearchSource();
      final source = [first, second].merged();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);

      addTearDown(subscription.cancel);
      source.initialize(SearchQueryContext.empty);

      first.emitSnapshot(readySnapshot(nodes: [resultNode("local")]));
      second.emitSnapshot(SearchSourceSnapshot.loading());

      expect(snapshots.last.status, SearchSourceStatus.loading);
      expect(resultIds(snapshots.last), ["local"]);
    });

    test("does not mix snapshots from different queries", () {
      final first = FakeSearchSource();
      final second = FakeSearchSource();
      final source = [first, second].merged();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);

      addTearDown(subscription.cancel);
      source.initialize(SearchQueryContext.empty);
      source.search(queryContext("old"));
      first.emitSnapshot(readySnapshot(nodes: [resultNode("old first")]));
      second.emitSnapshot(readySnapshot(nodes: [resultNode("old second")]));

      source.search(queryContext("new"));
      first.emitSnapshot(SearchSourceSnapshot.loading());

      expect(resultIds(snapshots.last), isEmpty);
      expect(snapshots.last.status, SearchSourceStatus.loading);
    });

    test("searches only sources that can satisfy the selector expression", () {
      final bookOnly = FakeSearchSource(
        selectors: [sourceBackedSelector("book")],
      );
      final tagOnly = FakeSearchSource(
        selectors: [sourceBackedSelector("tag")],
      );
      final combined = FakeSearchSource(
        selectors: [sourceBackedSelector("book"), sourceBackedSelector("tag")],
      );
      final source = [bookOnly, tagOnly, combined].merged();
      addTearDown(source.dispose);
      source.initialize(SearchQueryContext.empty);
      final book = SearchSelectorExpression.leaf(
        parsedSelector("book", "Harbor"),
      );
      final tag = SearchSelectorExpression.leaf(parsedSelector("tag", "Quest"));

      source.search(
        SearchQueryContext(
          normalizedQuery: "",
          selectors: [
            parsedSelector("book", "Harbor"),
            parsedSelector("tag", "Quest"),
          ],
          selectorExpression: SearchSelectorExpression.binary(
            operator: SearchSelectorOperator.and,
            left: book,
            right: tag,
          ),
        ),
      );

      expect(bookOnly.searches, isEmpty);
      expect(tagOnly.searches, isEmpty);
      expect(combined.searches, hasLength(1));
    });

    test("merges guidance diagnostics and selectors", () {
      final first = FakeSearchSource(
        selectors: const [KeyValueSelectorDefinition(id: "tag", key: "tag:")],
      );
      final second = FakeSearchSource(
        selectors: const [
          KeyValueSelectorDefinition(id: "world", key: "world:"),
        ],
      );
      final source = [first, second].merged();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];

      final snapshotSubscription = source.snapshots.listen(snapshots.add);
      addTearDown(snapshotSubscription.cancel);
      source.initialize(SearchQueryContext.empty);
      first.emitSnapshot(
        SearchSourceSnapshot.ready(
          nodes: [resultNode("first")],
          guidance: const [SearchGuidance(id: "first", title: "First")],
        ),
      );
      second.emitSnapshot(
        SearchSourceSnapshot.ready(
          nodes: [resultNode("second")],
          errorSummaries: const [
            SearchErrorSummary(
              id: "partial",
              message: "Web unavailable",
              severity: SearchErrorSeverity.warning,
            ),
          ],
        ),
      );

      expect(source.selectors.map((selector) => selector.id), ["tag", "world"]);
      expect(resultIds(snapshots.last), ["first", "second"]);
      expect(snapshots.last.guidance.single.id, "first");
      expect(snapshots.last.errorSummaries.single.id, "partial");
      expect(snapshots.last.status, SearchSourceStatus.ready);
    });

    test("all empty errors produce an error snapshot", () {
      final first = FakeSearchSource();
      final second = FakeSearchSource();
      final source = [first, second].merged();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);

      addTearDown(subscription.cancel);
      source.initialize(SearchQueryContext.empty);

      first.emitSnapshot(errorSnapshot("first", "First failed"));
      second.emitSnapshot(errorSnapshot("second", "Second failed"));

      expect(snapshots.last.status, SearchSourceStatus.error);
      expect(snapshots.last.errorSummaries, hasLength(2));
    });

    test("preview is routed to the child that produced the result", () async {
      final first = FakeSearchSource();
      final second = FakeSearchSource()
        ..previewResult = const SearchPreviewRequestResult.data(data: "second");
      final source = [first, second].merged();
      addTearDown(source.dispose);
      source.initialize(SearchQueryContext.empty);
      first.emitSnapshot(readySnapshot(nodes: [resultNode("first")]));

      second.emitSnapshot(readySnapshot(nodes: [resultNode("second")]));
      const request = SearchPreviewRequest(resultId: "second");

      final preview = await source.preview(request);

      expect(preview, const SearchPreviewRequestResult.data(data: "second"));
      expect(first.previewRequests, isEmpty);
      expect(second.previewRequests, [request]);
    });

    test("local and global limits compose differently", () {
      final localFirst = FakeSearchSource();
      final localSecond = FakeSearchSource();
      final globalFirst = FakeSearchSource();
      final globalSecond = FakeSearchSource();
      final locallyLimited = [
        localFirst.limited(1),
        localSecond.limited(1),
      ].merged();
      final globallyLimited = [globalFirst, globalSecond].merged().limited(1);

      addTearDown(locallyLimited.dispose);
      addTearDown(globallyLimited.dispose);
      final localSnapshots = <SearchSourceSnapshot>[];
      final globalSnapshots = <SearchSourceSnapshot>[];
      final localSubscription = locallyLimited.snapshots.listen(
        localSnapshots.add,
      );
      final globalSubscription = globallyLimited.snapshots.listen(
        globalSnapshots.add,
      );

      addTearDown(localSubscription.cancel);
      addTearDown(globalSubscription.cancel);
      locallyLimited.initialize(SearchQueryContext.empty);
      globallyLimited.initialize(SearchQueryContext.empty);

      localFirst.emitSnapshot(readySnapshot(nodes: [resultNode("one")]));
      localSecond.emitSnapshot(readySnapshot(nodes: [resultNode("two")]));
      globalFirst.emitSnapshot(readySnapshot(nodes: [resultNode("one")]));
      globalSecond.emitSnapshot(readySnapshot(nodes: [resultNode("two")]));

      expect(resultIds(localSnapshots.last), ["one", "two"]);
      expect(resultIds(globalSnapshots.last), ["one"]);
    });

    test("outer distinct removes duplicates from merged sections", () {
      final first = FakeSearchSource();
      final second = FakeSearchSource();
      final source = [
        first.inSection(id: "first", title: "First"),
        second.inSection(id: "second", title: "Second"),
      ].merged().distinct();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);

      addTearDown(subscription.cancel);
      source.initialize(SearchQueryContext.empty);

      first.emitSnapshot(readySnapshot(nodes: [resultNode("same")]));
      second.emitSnapshot(readySnapshot(nodes: [resultNode("same")]));

      expect(resultIds(snapshots.last), ["same"]);
      expect(snapshots.last.nodes, hasLength(1));
      expect((snapshots.last.nodes.single as SearchSectionNode).id, "first");
    });

    test("unions suggestions from every owner", () async {
      final first = FakeSearchSource(selectors: [sourceBackedSelector("page")])
        ..completionResult = const SearchSelectorCompletionResult(
          values: ["Intro", "Shared"],
          exhaustive: true,
        );
      final second = FakeSearchSource(selectors: [sourceBackedSelector("page")])
        ..completionResult = const SearchSelectorCompletionResult(
          values: ["shared", "Finale"],
          exhaustive: true,
        );
      final source = [first, second].merged();
      addTearDown(source.dispose);

      final result = await (source as SearchSelectorCompletionSource)
          .completeSelector(
            const SearchSelectorCompletionRequest(
              selectorId: "page",
              partial: "",
            ),
          );

      expect(result.values, ["Intro", "Shared", "Finale"]);
      expect(result.exhaustive, isTrue);
    });

    test(
      "routes completion only to owners compatible with its scope",
      () async {
        final constrained = FakeSearchSource(
          selectors: [
            sourceBackedSelector("page"),
            sourceBackedSelector("tag"),
          ],
        );
        final unconstrained = FakeSearchSource(
          selectors: [sourceBackedSelector("page")],
        );
        final source = [constrained, unconstrained].merged();
        addTearDown(source.dispose);
        final scope = SearchSelectorExpression.leaf(
          parsedSelector("tag", "quest"),
        );

        await (source as SearchSelectorCompletionSource).completeSelector(
          SearchSelectorCompletionRequest(
            selectorId: "page",
            partial: "intro",
            scope: scope,
          ),
        );

        expect(constrained.completionRequests, hasLength(1));
        expect(constrained.completionRequests.single.scope, scope);
        expect(unconstrained.completionRequests, isEmpty);
      },
    );

    test("keeps completion failure local when every owner fails", () async {
      final first = FakeSearchSource(selectors: [sourceBackedSelector("page")])
        ..completionError = StateError("first failed");
      final second = FakeSearchSource(selectors: [sourceBackedSelector("page")])
        ..completionError = StateError("second failed");
      final source = [first, second].merged();
      addTearDown(source.dispose);

      final result = await (source as SearchSelectorCompletionSource)
          .completeSelector(
            const SearchSelectorCompletionRequest(
              selectorId: "page",
              partial: "intro",
            ),
          );

      expect(result.values, isEmpty);
      expect(result.warning, isNotNull);
    });

    test("retains available suggestions when one owner fails", () async {
      final available =
          FakeSearchSource(selectors: [sourceBackedSelector("page")])
            ..completionResult = const SearchSelectorCompletionResult(
              values: ["Arrival"],
              exhaustive: true,
            );
      final unavailable = FakeSearchSource(
        selectors: [sourceBackedSelector("page")],
      )..completionError = StateError("failed");
      final source = [available, unavailable].merged();
      addTearDown(source.dispose);

      final result = await (source as SearchSelectorCompletionSource)
          .completeSelector(
            const SearchSelectorCompletionRequest(
              selectorId: "page",
              partial: "",
            ),
          );

      expect(result.values, ["Arrival"]);
      expect(result.warning, isNotNull);
    });

    test("acceptance from one owner wins shared selector validation", () {
      final first = FakeSearchSource(selectors: [sourceBackedSelector("book")]);
      final second = FakeSearchSource(
        selectors: [sourceBackedSelector("book")],
      );
      final source = [first, second].merged();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      source.initialize(SearchQueryContext.empty);
      source.search(selectorContext("book", "Main"));

      first.emitSnapshot(
        SearchSourceSnapshot.ready(
          nodes: const [],
          selectorValidations: [
            selectorValidation(
              "book",
              "Main",
              SearchSelectorValidationStatus.rejected,
            ),
          ],
        ),
      );
      second.emitSnapshot(
        SearchSourceSnapshot.ready(
          nodes: const [],
          selectorValidations: [
            selectorValidation(
              "book",
              "main",
              SearchSelectorValidationStatus.accepted,
            ),
          ],
        ),
      );

      expect(
        snapshots.last.selectorValidations.single.status,
        SearchSelectorValidationStatus.accepted,
      );
    });

    test("rejects only when every active owner rejects", () {
      final first = FakeSearchSource(selectors: [sourceBackedSelector("book")]);
      final second = FakeSearchSource(
        selectors: [sourceBackedSelector("book")],
      );
      final source = [first, second].merged();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      source.initialize(SearchQueryContext.empty);
      source.search(selectorContext("book", "Missing"));

      for (final child in [first, second]) {
        child.emitSnapshot(
          SearchSourceSnapshot.ready(
            nodes: const [],
            selectorValidations: [
              selectorValidation(
                "book",
                "Missing",
                SearchSelectorValidationStatus.rejected,
              ),
            ],
          ),
        );
      }

      expect(
        snapshots.last.selectorValidations.single.status,
        SearchSelectorValidationStatus.rejected,
      );
    });

    test("leaves validation unresolved when an owner is unavailable", () {
      final first = FakeSearchSource(selectors: [sourceBackedSelector("book")]);
      final second = FakeSearchSource(
        selectors: [sourceBackedSelector("book")],
      );
      final source = [first, second].merged();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      source.initialize(SearchQueryContext.empty);
      source.search(selectorContext("book", "Missing"));

      first.emitSnapshot(
        SearchSourceSnapshot.ready(
          nodes: const [],
          selectorValidations: [
            selectorValidation(
              "book",
              "Missing",
              SearchSelectorValidationStatus.rejected,
            ),
          ],
        ),
      );
      second.emitSnapshot(errorSnapshot("second", "Unavailable"));

      expect(
        snapshots.last.selectorValidations.single.status,
        SearchSelectorValidationStatus.unresolved,
      );
    });

    test("rejects conflicting definitions from shared owners", () {
      final first = FakeSearchSource(selectors: [sourceBackedSelector("book")]);
      final second = FakeSearchSource(
        selectors: const [
          KeyValueSelectorDefinition(
            id: "book",
            key: "library:",
            value: QuerySelectorValue.sourceBacked(),
          ),
        ],
      );

      expect(() => [first, second].merged(), throwsA(isA<StateError>()));
    });
  });
}

KeyValueSelectorDefinition sourceBackedSelector(String id) {
  return KeyValueSelectorDefinition(
    id: id,
    key: "$id:",
    value: const QuerySelectorValue.sourceBacked(),
  );
}

SearchParsedSelector parsedSelector(String id, String value) {
  return SearchParsedSelector(selectorId: id, key: "$id:", value: value);
}

SearchQueryContext selectorContext(String id, String value) {
  final selector = parsedSelector(id, value);
  return SearchQueryContext(
    normalizedQuery: "$id:$value",
    selectors: [selector],
    selectorExpression: SearchSelectorExpression.leaf(selector),
  );
}

SearchSelectorValidation selectorValidation(
  String id,
  String value,
  SearchSelectorValidationStatus status,
) {
  return SearchSelectorValidation(selectorId: id, value: value, status: status);
}

SearchQueryContext queryContext(String query) {
  return SearchQueryContext(normalizedQuery: query, selectors: const []);
}

SearchSourceSnapshot errorSnapshot(String id, String message) {
  return SearchSourceSnapshot.error(
    errorSummaries: [
      SearchErrorSummary(
        id: id,
        message: message,
        severity: SearchErrorSeverity.error,
      ),
    ],
  );
}

List<String> resultIds(SearchSourceSnapshot snapshot) {
  return snapshot.nodes
      .walk()
      .whereType<SearchResultNode>()
      .map((node) => node.result.id)
      .toList();
}
