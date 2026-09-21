import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
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

    test(
      "replaces authoritative diagnostics instead of duplicating them",
      () async {
        final diagnostic = _diagnostic("One definition was rejected");
        final fetched = RealmEditorCatalogFetched(
          RealmEditorCatalogSnapshot(
            catalog: TypeCatalog([]),
            generation: const CatalogGeneration("4"),
            diagnostics: [diagnostic],
          ),
        );
        final source = _FakeSource()
          ..responses.addAll([Future.value(fetched), Future.value(fetched)]);
        final cache = _cache(source);
        addTearDown(cache.dispose);
        cache.start();

        await _waitFor(() => source.requests.length == 1);

        await cache.refresh();

        final ready = await cache.states.firstWhere(
          (state) => state is RealmEditorCatalogReady,
        );
        expect(ready.snapshot!.diagnostics, [diagnostic]);
      },
    );

    test(
      "fetches the union of active leases and releases closed demand",
      () async {
        final firstType = _type("first");
        final secondType = _type("second");
        final source = _FakeSource()
          ..responses.addAll([
            Future.value(_fetched("1")),
            Future.value(_fetched("1")),
            Future.value(_fetched("1")),
            Future.value(_fetched("1")),
          ]);
        final cache = _cache(source);
        addTearDown(cache.dispose);
        cache.start();

        await _waitFor(() => source.requests.length == 1);
        final firstLease = cache.acquire(
          RealmEditorCatalogRequest(types: {firstType}),
        );
        addTearDown(firstLease.close);
        await _waitFor(() => source.requests.length == 2);
        final secondLease = cache.acquire(
          RealmEditorCatalogRequest(types: {secondType}),
        );
        addTearDown(secondLease.close);

        await _waitFor(() => source.requests.length == 3);
        expect(source.requests[1].types, {firstType});
        expect(source.requests[2].types, {firstType, secondType});
        firstLease.close();
        await cache.refresh();
        expect(source.requests[3].types, {secondType});
      },
    );

    test(
      "exact generation fetch reuses covered snapshots and exposes mismatch",
      () async {
        final firstType = _type("first");
        final secondType = _type("second");
        final firstRequest = RealmEditorCatalogRequest(types: {firstType});
        final source = _FakeSource()
          ..responses.addAll([
            Future.value(_fetched("7")),
            Future.value(
              const RealmEditorCatalogGenerationMismatch(
                CatalogGeneration("8"),
              ),
            ),
          ]);
        final cache = _cache(source);
        addTearDown(cache.dispose);
        final lease = cache.acquire(firstRequest);
        addTearDown(lease.close);
        cache.start();
        await cache.states.firstWhere(
          (state) => state.snapshot?.generation.value == "7",
        );

        final retained = await cache.fetchExact(
          const CatalogGeneration("7"),
          firstRequest,
        );
        expect(retained, isA<RealmEditorCatalogFetched>());
        expect(source.requests, hasLength(1));

        final mismatch = await cache.fetchExact(
          const CatalogGeneration("7"),
          RealmEditorCatalogRequest(types: {firstType, secondType}),
        );
        expect(mismatch, isA<RealmEditorCatalogGenerationMismatch>());
        expect(source.requests, hasLength(2));
        expect(source.requestedGenerations.last, const CatalogGeneration("7"));
      },
    );

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
    test("retains the previous snapshot after a retry mismatch", () async {
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
      final lease = cache.acquire(
        RealmEditorCatalogRequest(
          presentations: {PresentationId(namespace: "test", name: "updated")},
        ),
      );
      addTearDown(lease.close);
      expect(
        (await unavailable as RealmEditorCatalogUnavailable).previous,
        isNotNull,
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

    test("pin adopts visual changes and pauses for schema changes", () async {
      final type = _type("resource");
      final presentation = PresentationId(namespace: "test", name: "summary");
      final request = RealmEditorCatalogRequest(types: {type});
      final source = _FakeSource()
        ..responses.addAll([
          Future.value(
            _catalogFetched(
              "1",
              type: type,
              presentation: presentation,
              label: "Before",
            ),
          ),
          Future.value(
            _catalogFetched(
              "2",
              type: type,
              presentation: presentation,
              label: "After",
            ),
          ),
          Future.value(
            _catalogFetched(
              "3",
              type: type,
              presentation: presentation,
              label: "After",
              representation: const IntegerType(width: IntegerWidth.signed64),
            ),
          ),
        ]);
      final cache = _cache(source);
      addTearDown(cache.dispose);
      final firstReady = cache.states.firstWhere(
        (state) => state.snapshot?.generation.value == "1",
      );
      cache.start();
      await firstReady;
      final pin = cache.pin(request);
      addTearDown(pin.dispose);

      await _waitFor(() => pin.state.snapshot.generation.value == "2");
      expect(pin.state.paused, isFalse);

      await cache.refresh();
      await _waitFor(() => pin.state.paused);
      expect(pin.state.snapshot.generation.value, "2");
      expect(pin.state.pending?.generation.value, "3");
      expect(await pin.reconcile((_, _) async => false), isFalse);
      expect(pin.state.paused, isTrue);
      expect(await pin.reconcile((_, _) async => true), isTrue);
      expect(pin.state.snapshot.generation.value, "3");
    });
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

RealmEditorCatalogFetched _catalogFetched(
  String generation, {
  required ResolvedTypeRef type,
  required PresentationId presentation,
  required String label,
  TypeExpression representation = const StringType(),
}) => RealmEditorCatalogFetched(
  RealmEditorCatalogSnapshot(
    catalog: TypeCatalog([
      TypeDefinition(
        id: type,
        kind: NominalTypeKind.concrete,
        representation: representation,
        rolePresentations: {PresentationRole.referenceSummary: presentation},
      ),
    ]),
    generation: CatalogGeneration(generation),
    presentations: {
      presentation: PresentationDefinition.single(
        id: presentation,
        target: NamedType(type),
        root: PresentationNode(
          id: "root",
          element: TextElement(label.asStringLiteral),
        ),
      ),
    },
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
  Future<RealmTypedValueInitializationResult> initialize(
    RealmEditorCatalogRoute route, {
    required CatalogGeneration generation,
    required TypedValueEnvelope partial,
    required TypeRegistry registry,
  }) => Future.error(UnsupportedError("Initialization is outside this test"));

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
