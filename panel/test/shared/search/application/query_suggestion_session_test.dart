import "dart:async";

import "package:fake_async/fake_async.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  const firstRequest = SearchSelectorCompletionRequest(
    selectorId: "page",
    partial: "a",
  );
  const secondRequest = SearchSelectorCompletionRequest(
    selectorId: "page",
    partial: "b",
  );

  test("debounces completion requests", () {
    fakeAsync((async) {
      final requests = <SearchSelectorCompletionRequest>[];
      final session = QuerySuggestionSession(
        completeSelector: (request) async {
          requests.add(request);
          return const SearchSelectorCompletionResult(values: ["arrival"]);
        },
      );
      addTearDown(session.dispose);

      session.update(firstRequest);
      async.elapse(const Duration(milliseconds: 149));
      expect(requests, isEmpty);

      async
        ..elapse(const Duration(milliseconds: 1))
        ..flushMicrotasks();
      expect(requests, [firstRequest]);
    });
  });

  test("publishes only the latest completion", () {
    fakeAsync((async) {
      final completions =
          <
            SearchSelectorCompletionRequest,
            Completer<SearchSelectorCompletionResult>
          >{};
      final session = QuerySuggestionSession(
        completeSelector: (request) {
          final completion = Completer<SearchSelectorCompletionResult>();
          completions[request] = completion;
          return completion.future;
        },
      );
      addTearDown(session.dispose);

      session.update(firstRequest);
      async.elapse(const Duration(milliseconds: 150));
      session.update(secondRequest);
      async.elapse(const Duration(milliseconds: 150));

      completions[firstRequest]!.complete(
        const SearchSelectorCompletionResult(values: ["arrival"]),
      );
      async.flushMicrotasks();
      expect(session.value.values, isEmpty);

      completions[secondRequest]!.complete(
        const SearchSelectorCompletionResult(values: ["bravo"]),
      );
      async.flushMicrotasks();
      expect(session.value.values, ["bravo"]);
    });
  });

  test("reuses exhaustive completion for a narrower partial", () {
    fakeAsync((async) {
      var requestCount = 0;
      final session = QuerySuggestionSession(
        completeSelector: (_) async {
          requestCount++;
          return const SearchSelectorCompletionResult(
            values: ["arrival"],
            exhaustive: true,
          );
        },
      );
      addTearDown(session.dispose);

      session.update(firstRequest);
      async
        ..elapse(const Duration(milliseconds: 150))
        ..flushMicrotasks();
      session.update(
        const SearchSelectorCompletionRequest(
          selectorId: "page",
          partial: "ar",
        ),
      );
      async
        ..flushMicrotasks()
        ..elapse(const Duration(milliseconds: 150))
        ..flushMicrotasks();

      expect(requestCount, 1);
      expect(session.value.values, ["arrival"]);
    });
  });

  test("converts completion failures into a warning", () {
    fakeAsync((async) {
      final session = QuerySuggestionSession(
        completeSelector: (_) => throw StateError("unavailable"),
      );
      addTearDown(session.dispose);

      session.update(firstRequest);
      async
        ..elapse(const Duration(milliseconds: 150))
        ..flushMicrotasks();

      expect(session.value.values, isEmpty);
      expect(
        session.value.warning,
        "Selector suggestions are temporarily unavailable",
      );
    });
  });
}
