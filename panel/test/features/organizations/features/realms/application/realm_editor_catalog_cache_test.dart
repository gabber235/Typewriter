import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("Realm editor catalog models", () {
    test("requests use value equality, immutable sets, and copyWith", () {
      final request = RealmEditorCatalogRequest(types: {_type("first")});
      final copied = request.copyWith(types: {_type("second")});

      expect(request, RealmEditorCatalogRequest(types: {_type("first")}));
      expect(request.types, {_type("first")});
      expect(() => request.types.add(_type("other")), throwsUnsupportedError);
      expect(copied.types, {_type("second")});
    });

    test("cases use value equality and support copyWith", () {
      final snapshot = RealmEditorCatalogSnapshot(
        catalog: TypeCatalog([]),
        generation: const CatalogGeneration("1"),
      );
      final copiedSnapshot = snapshot.copyWith(
        generation: const CatalogGeneration("2"),
      );

      expect(
        RealmEditorCatalogState.ready(snapshot),
        RealmEditorCatalogState.ready(snapshot),
      );
      expect(
        RealmEditorCatalogFetchResult.fetched(snapshot),
        RealmEditorCatalogFetchResult.fetched(snapshot),
      );
      expect(
        const RealmEditorCatalogWatchEvent.invalidated(CatalogGeneration("1")),
        const RealmEditorCatalogWatchEvent.invalidated(CatalogGeneration("1")),
      );
      expect(copiedSnapshot.generation, const CatalogGeneration("2"));
      expect(
        (RealmEditorCatalogState.ready(snapshot) as RealmEditorCatalogReady)
            .copyWith(value: copiedSnapshot)
            .value,
        copiedSnapshot,
      );
    });

    test("unavailable cases use immutable diagnostics", () {
      final state = RealmEditorCatalogState.unavailable([
        _diagnostic("Unavailable"),
      ]);
      final fetch = RealmEditorCatalogFetchResult.unavailable([
        _diagnostic("Unavailable"),
      ]);
      final watch = RealmEditorCatalogWatchEvent.unavailable([
        _diagnostic("Unavailable"),
      ]);

      expect(
        state,
        RealmEditorCatalogState.unavailable([_diagnostic("Unavailable")]),
      );
      expect(
        fetch,
        RealmEditorCatalogFetchResult.unavailable([_diagnostic("Unavailable")]),
      );
      expect(
        watch,
        RealmEditorCatalogWatchEvent.unavailable([_diagnostic("Unavailable")]),
      );
      expect(
        (state as RealmEditorCatalogUnavailable).diagnostics.clear,
        throwsUnsupportedError,
      );
      expect(
        (fetch as RealmEditorCatalogFetchUnavailable)
            .copyWith(diagnostics: [_diagnostic("Retry")])
            .diagnostics
            .single
            .message,
        "Retry",
      );
      expect(
        (watch as RealmEditorCatalogWatchUnavailable)
            .copyWith(diagnostics: [_diagnostic("Closed")])
            .diagnostics
            .single
            .message,
        "Closed",
      );
    });
  });

  group("RealmEditorCatalogCache", () {
    test("publishes a fetched catalog with partial diagnostics", () async {
      final diagnostic = _diagnostic("One definition was rejected");
      final source = _FakeSource()
        ..responses.add(
          Future.value(
            RealmEditorCatalogFetched(
              RealmEditorCatalogSnapshot(
                catalog: TypeCatalog([]),
                generation: const CatalogGeneration("4"),
                diagnostics: [diagnostic],
              ),
            ),
          ),
        );
      final cache = _cache(source);
      addTearDown(cache.dispose);
      final states = <RealmEditorCatalogState>[];
      final subscription = cache.states.listen(states.add);
      addTearDown(subscription.cancel);
      cache.start();
      await _waitFor(
        () => states.whereType<RealmEditorCatalogReady>().isNotEmpty,
      );
      final ready = states.whereType<RealmEditorCatalogReady>().last;
      expect(ready.value.generation, const CatalogGeneration("4"));
      expect(ready.value.diagnostics, [diagnostic]);
    });

    test("accumulates focused requests for lazy catalog batches", () async {
      final firstType = _type("first");
      final secondType = _type("second");
      final source = _FakeSource()
        ..responses.addAll([
          Future.value(_fetched("1")),
          Future.value(_fetched("1")),
          Future.value(_fetched("1")),
        ]);
      final cache = _cache(source);
      addTearDown(cache.dispose);
      cache.start();
      await _waitFor(() => source.requests.length == 1);
      cache.request(RealmEditorCatalogRequest(types: {firstType}));
      await _waitFor(() => source.requests.length == 2);
      cache.request(RealmEditorCatalogRequest(types: {secondType}));
      await _waitFor(() => source.requests.length == 3);
      expect(source.requests[1].types, {firstType});
      expect(source.requests[2].types, {firstType, secondType});
    });

    test("refreshes with the invalidated generation", () async {
      final source = _FakeSource()
        ..responses.addAll([
          Future.value(_fetched("1")),
          Future.value(_fetched("2")),
        ]);
      final cache = _cache(source);
      addTearDown(cache.dispose);
      final states = <RealmEditorCatalogState>[];
      final subscription = cache.states.listen(states.add);
      addTearDown(subscription.cancel);
      cache.start();
      await _waitFor(() => source.requestedGenerations.length == 1);

      source.events.add(
        const RealmEditorCatalogInvalidated(CatalogGeneration("2")),
      );
      await _waitFor(() => source.requestedGenerations.length == 2);
      expect(source.requestedGenerations, [null, const CatalogGeneration("2")]);
      await _waitFor(
        () => states.whereType<RealmEditorCatalogReady>().any(
          (state) => state.value.generation == const CatalogGeneration("2"),
        ),
      );
    });

    test("retries one generation mismatch", () async {
      final source = _FakeSource()
        ..responses.addAll([
          Future.value(
            const RealmEditorCatalogGenerationMismatch(CatalogGeneration("8")),
          ),
          Future.value(_fetched("8")),
        ]);
      final cache = _cache(source);
      addTearDown(cache.dispose);
      final states = <RealmEditorCatalogState>[];
      final subscription = cache.states.listen(states.add);
      addTearDown(subscription.cancel);
      cache.start();
      await _waitFor(
        () => states.whereType<RealmEditorCatalogReady>().isNotEmpty,
      );

      expect(source.requestedGenerations, [null, const CatalogGeneration("8")]);
      expect(
        states.whereType<RealmEditorCatalogReady>().last.value.generation,
        const CatalogGeneration("8"),
      );
    });

    test("stops after a second generation mismatch", () async {
      final source = _FakeSource()
        ..responses.addAll([
          Future.value(
            const RealmEditorCatalogGenerationMismatch(CatalogGeneration("3")),
          ),
          Future.value(
            const RealmEditorCatalogGenerationMismatch(CatalogGeneration("4")),
          ),
        ]);
      final cache = _cache(source);
      addTearDown(cache.dispose);
      final states = <RealmEditorCatalogState>[];
      final subscription = cache.states.listen(states.add);
      addTearDown(subscription.cancel);

      cache.start();
      await _waitFor(
        () => states.whereType<RealmEditorCatalogUnavailable>().isNotEmpty,
      );

      expect(source.requestedGenerations, [null, const CatalogGeneration("3")]);
      final unavailable = states
          .whereType<RealmEditorCatalogUnavailable>()
          .last;
      expect(
        unavailable.diagnostics.single.code,
        TypeDiagnosticCode.invalidRevision,
      );
    });
    test("clears the previous snapshot before retrying a mismatch", () async {
      final source = _FakeSource()
        ..responses.addAll([
          Future.value(_fetched("1")),
          Future.value(
            const RealmEditorCatalogGenerationMismatch(CatalogGeneration("2")),
          ),
          Future.value(
            const RealmEditorCatalogGenerationMismatch(CatalogGeneration("3")),
          ),
        ]);
      final cache = _cache(source);
      addTearDown(cache.dispose);
      final ready = cache.states.firstWhere(
        (state) => state is RealmEditorCatalogReady,
      );
      cache.start();
      await ready;
      final unavailable = cache.states.firstWhere(
        (state) => state is RealmEditorCatalogUnavailable,
      );
      cache.request(
        RealmEditorCatalogRequest(
          presentations: {PresentationId(namespace: "test", name: "updated")},
        ),
      );
      expect(
        (await unavailable as RealmEditorCatalogUnavailable).previous,
        isNull,
      );
    });
    test("rejects a stale fetch response with a local epoch", () async {
      final first = Completer<RealmEditorCatalogFetchResult>();
      final second = Completer<RealmEditorCatalogFetchResult>();
      final source = _FakeSource()
        ..responses.addAll([first.future, second.future]);
      final cache = _cache(source);
      addTearDown(cache.dispose);
      final states = <RealmEditorCatalogState>[];
      final subscription = cache.states.listen(states.add);
      addTearDown(subscription.cancel);
      cache.start();
      await _waitFor(() => source.requestedGenerations.length == 1);

      source.events.add(
        const RealmEditorCatalogInvalidated(CatalogGeneration("2")),
      );
      await _waitFor(() => source.requestedGenerations.length == 2);
      second.complete(_fetched("2"));
      await _waitFor(
        () => states.whereType<RealmEditorCatalogReady>().any(
          (state) => state.value.generation == const CatalogGeneration("2"),
        ),
      );
      first.complete(_fetched("1"));
      await Future<void>.delayed(Duration.zero);

      expect(
        states.whereType<RealmEditorCatalogReady>().map(
          (state) => state.value.generation,
        ),
        [const CatalogGeneration("2")],
      );
    });

    test(
      "preserves the last catalog when the watch becomes unavailable",
      () async {
        final source = _FakeSource()
          ..responses.add(Future.value(_fetched("6")));
        final cache = _cache(source);
        addTearDown(cache.dispose);
        final states = <RealmEditorCatalogState>[];
        final subscription = cache.states.listen(states.add);
        addTearDown(subscription.cancel);
        cache.start();
        await _waitFor(
          () => states.whereType<RealmEditorCatalogReady>().isNotEmpty,
        );

        source.events.add(
          RealmEditorCatalogWatchUnavailable([
            _diagnostic("Watch unavailable"),
          ]),
        );
        await _waitFor(
          () => states.whereType<RealmEditorCatalogUnavailable>().isNotEmpty,
        );

        expect(
          states
              .whereType<RealmEditorCatalogUnavailable>()
              .last
              .previous
              ?.generation,
          const CatalogGeneration("6"),
        );
      },
    );
  });
}

RealmEditorCatalogCache _cache(_FakeSource source) => RealmEditorCatalogCache(
  source: source,
  route: RealmEditorCatalogRoute(
    organizationId: recordId("organization:test"),
    realmId: recordId("service:test"),
  ),
);

RealmEditorCatalogFetched _fetched(String generation) =>
    RealmEditorCatalogFetched(
      RealmEditorCatalogSnapshot(
        catalog: TypeCatalog([]),
        generation: CatalogGeneration(generation),
      ),
    );

TypeDiagnostic _diagnostic(String message) => TypeDiagnostic(
  code: TypeDiagnosticCode.invalidConstraint,
  message: message,
  pathPresent: false,
);

ResolvedTypeRef _type(String name) => ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "test", name: name),
  revision: 1,
);

Future<void> _waitFor(bool Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail("Condition was not reached");
}

final class _FakeSource implements RealmEditorCatalogSource {
  final responses = <Future<RealmEditorCatalogFetchResult>>[];
  final requestedGenerations = <CatalogGeneration?>[];
  final requests = <RealmEditorCatalogRequest>[];
  final events = StreamController<RealmEditorCatalogWatchEvent>();

  @override
  Future<RealmEditorCatalogFetchResult> fetch(
    RealmEditorCatalogRoute route,
    RealmEditorCatalogRequest request, {
    CatalogGeneration? expectedGeneration,
  }) {
    requestedGenerations.add(expectedGeneration);
    requests.add(request);
    return responses.removeAt(0);
  }

  @override
  Stream<RealmEditorCatalogWatchEvent> watchInvalidations(
    RealmEditorCatalogRoute route,
  ) => events.stream;
}
