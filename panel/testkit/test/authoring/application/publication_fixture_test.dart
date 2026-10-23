import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

final _scope = AuthoringScope(
  organizationId: skir.recordId("organization:publication"),
  realmId: skir.recordId("realm:publication"),
);
const _deliveryTimeout = Duration(seconds: 2);

PublicationObservation _empty() => PublicationObservation.available(
  skir.PublicationView(
    id: skir.PublicationViewId(value: "empty"),
    status: skir.PublicationStatus.createEmpty(notices: const []),
  ),
);

void main() {
  test("replay and ordinary updates preserve observations emitted by their listeners", () async {
    final initial = _empty();
    final changed = PublicationObservation.unavailable("Disconnected");
    final invalidated = PublicationObservation.unavailable("Observation lost");
    final repository = TestPublicationRepository(_scope, initial: initial);
    final seen = <PublicationObservation>[];
    final delivered = Completer<void>();
    final subscription = repository.watch().listen((observation) {
      seen.add(observation);
      if (identical(observation, initial)) repository.observe(changed);
      if (identical(observation, changed)) repository.observe(invalidated);
      if (identical(observation, invalidated)) delivered.complete();
    });
    try {
      await delivered.future.timeout(_deliveryTimeout);
      expect(seen, [initial, changed, invalidated]);
      expect(repository.current, same(invalidated));
    } finally {
      await subscription.cancel();
      await repository.close();
    }
  });

  test(
    "updates immediately after listening reach every watcher in order",
    () async {
      final initial = _empty();
      final repository = TestPublicationRepository(_scope, initial: initial);
      final first = <PublicationObservation>[];
      final second = <PublicationObservation>[];
      final firstDelivered = Completer<void>();
      final secondDelivered = Completer<void>();
      final changed = PublicationObservation.fetching(
        skir.PublicationViewId(value: "next"),
      );
      final unavailable = PublicationObservation.unavailable("Disconnected");
      final subscriptions = [
        repository.watch().listen((value) {
          first.add(value);
          if (identical(value, unavailable)) firstDelivered.complete();
        }),
        repository.watch().listen((value) {
          second.add(value);
          if (identical(value, unavailable)) secondDelivered.complete();
        }),
      ];
      try {
        expect(first, isEmpty);
        expect(second, isEmpty);
        repository
          ..observe(changed)
          ..observe(unavailable);
        expect(repository.current, same(unavailable));
        await Future.wait([firstDelivered.future, secondDelivered.future])
            .timeout(_deliveryTimeout);
        expect(first, [initial, changed, unavailable]);
        expect(second, first);
      } finally {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
        await repository.close();
      }
    },
  );

  test(
    "cancelled watchers stop and late watchers replay the current observation",
    () async {
      final initial = _empty();
      final repository = TestPublicationRepository(_scope, initial: initial);
      final replayed = Completer<void>();
      final seen = <PublicationObservation>[];
      final subscription = repository.watch().listen((value) {
        seen.add(value);
        if (!replayed.isCompleted) replayed.complete();
      });
      try {
        await replayed.future.timeout(_deliveryTimeout);
        await subscription.cancel();
        final next = PublicationObservation.unavailable("Disconnected");
        repository.observe(next);
        expect(
          await repository.watch().first.timeout(_deliveryTimeout),
          same(next),
        );
        expect(seen, [initial]);
      } finally {
        await subscription.cancel();
        await repository.close();
      }
    },
  );

  test("default repositories start empty and remain isolated by scope and container", () async {
    final container = ProviderContainer(
      overrides: [...appOverrides(), ...authoringFixtureOverrides()],
    );
    final otherContainer = ProviderContainer(
      overrides: [...appOverrides(), ...authoringFixtureOverrides()],
    );
    final sameRealm = AuthoringScope(
      organizationId: skir.recordId("organization:other"),
      realmId: _scope.realmId,
    );
    final sameOrganization = AuthoringScope(
      organizationId: _scope.organizationId,
      realmId: skir.recordId("realm:other"),
    );
    TestPublicationRepository read(
      ProviderContainer owner,
      AuthoringScope scope,
    ) => owner.read(
      realmPublicationRepositoryProvider(scope.organizationId, scope.realmId),
    ) as TestPublicationRepository;
    try {
      final first = read(container, _scope);
      final otherOrganization = read(container, sameRealm);
      final otherRealm = read(container, sameOrganization);
      final otherOwner = read(otherContainer, _scope);
      final repositories = [first, otherOrganization, otherRealm, otherOwner];
      expect(repositories.toSet(), hasLength(4));
      expect(repositories.map((repository) => repository.scope), [
        _scope,
        sameRealm,
        sameOrganization,
        _scope,
      ]);
      for (final repository in repositories) {
        final observation = await repository.watch().first.timeout(
          _deliveryTimeout,
        ) as AvailablePublicationObservation;
        expect(observation.view.id.value, isNotEmpty);
        expect(
          observation.view.status,
          skir.PublicationStatus.createEmpty(notices: const []),
        );
      }
      final changed = PublicationObservation.unavailable(
        "Only the first realm is unavailable",
      );
      first.observe(changed);
      expect(read(container, _scope), same(first));
      expect(
        await first.watch().first.timeout(_deliveryTimeout),
        same(changed),
      );
      for (final repository in repositories.skip(1)) {
        expect(repository.current, isA<AvailablePublicationObservation>());
      }
    } finally {
      container.dispose();
      otherContainer.dispose();
    }
  });

  test(
    "provider disposal closes defaults and rejects further observations",
    () async {
      final container = ProviderContainer(
        overrides: [...appOverrides(), ...authoringFixtureOverrides()],
      );
      final repository = container.read(
        realmPublicationRepositoryProvider(
          _scope.organizationId,
          _scope.realmId,
        ),
      ) as TestPublicationRepository;
      final closed = repository.watch().drain<void>();
      container.dispose();
      await closed.timeout(_deliveryTimeout);
      expect(() => repository.observe(_empty()), throwsStateError);
    },
  );

  test(
    "supplied repositories remain caller owned after provider disposal",
    () async {
      final initial = _empty();
      final supplied = TestPublicationRepository(_scope, initial: initial);
      addTearDown(supplied.close);
      final container = ProviderContainer(
        overrides: [
          ...appOverrides(),
          ...authoringFixtureOverrides(scope: _scope, publication: supplied),
        ],
      );
      try {
        expect(
          container.read(
            realmPublicationRepositoryProvider(
              _scope.organizationId,
              _scope.realmId,
            ),
          ),
          same(supplied),
        );
        expect(
          await supplied.watch().first.timeout(_deliveryTimeout),
          same(initial),
        );
      } finally {
        container.dispose();
      }
      final next = PublicationObservation.unavailable(
        "Caller still owns this repository",
      );
      supplied.observe(next);
      expect(
        await supplied.watch().first.timeout(_deliveryTimeout),
        same(next),
      );
    },
  );

  for (final mismatch in [
    AuthoringScope(
      organizationId: _scope.organizationId,
      realmId: skir.recordId("realm:other"),
    ),
    AuthoringScope(
      organizationId: skir.recordId("organization:other"),
      realmId: _scope.realmId,
    ),
  ]) {
    test("a supplied repository rejects scope $mismatch", () async {
      final supplied = TestPublicationRepository(_scope, initial: _empty());
      final container = ProviderContainer(
        overrides: [
          ...appOverrides(),
          ...authoringFixtureOverrides(scope: _scope, publication: supplied),
        ],
      );
      try {
        expect(
          () => container.read(
            realmPublicationRepositoryProvider(
              mismatch.organizationId,
              mismatch.realmId,
            ),
          ),
          throwsA(
            isA<Object>().having(
              (error) => error.toString(),
              "scope rejection message",
              contains(
                "Publication fixture scope does not match the requested realm",
              ),
            ),
          ),
        );
      } finally {
        container.dispose();
        await supplied.close();
      }
    });
  }

  test("unscripted publication effects fail explicitly", () async {
    final repository = TestPublicationRepository(_scope, initial: _empty());
    final candidate = skir.PublicationCandidateId(value: "candidate");
    final selection = skir.CompilationStatusSelection.wrapSuppliedRoots([
      skir.CompilationRoot(
        projection: skir.CompilationProjectionId(
          value: "typewriter.resource-graph",
        ),
        resource: skir.ResourceId(value: "saved"),
      ),
    ]);
    try {
      await expectLater(
        repository.preparePublish(candidate).send(),
        throwsStateError,
      );
      expect(repository.candidates, [candidate]);
      await expectLater(repository.states(selection), throwsStateError);
    } finally {
      await repository.close();
    }
  });

  test("scripts receive the requested selection and capture candidates only when sent", () async {
    final initial = _empty();
    final repository = TestPublicationRepository(_scope, initial: initial);
    final candidate = skir.PublicationCandidateId(value: "reviewed");
    final reply = SubmissionConfirmed(skir.PublishAuthoringResponse.noChanges);
    final root = skir.CompilationRoot(
      projection: skir.CompilationProjectionId(
        value: "typewriter.resource-graph",
      ),
      resource: skir.ResourceId(value: "saved"),
    );
    final selection = skir.CompilationStatusSelection.wrapSuppliedRoots([root]);
    final selections = <skir.CompilationStatusSelection>[];
    final statuses = [
      skir.CompiledResourceStatus(
        root: root,
        state: skir.CompiledResourceState.wrapActive(
          skir.PublicationId(value: "published"),
        ),
      ),
    ];
    repository
      ..send = () async {
        return reply;
      }
      ..readStates = (requested) async {
        selections.add(requested);
        return statuses;
      };
    try {
      final request = repository.preparePublish(candidate);
      expect(repository.candidates, isEmpty);
      expect(request.resources, {
        WorkDriverId(domain: "publication", scope: _scope),
      });
      expect(request.replay, SubmissionReplay.unsupported);
      expect(await request.send(), same(reply));
      expect(repository.candidates, [candidate]);
      expect(() => repository.candidates.clear(), throwsUnsupportedError);
      expect(await repository.states(selection), same(statuses));
      expect(selections, [selection]);
      expect(repository.current, same(initial));
    } finally {
      await repository.close();
    }
  });
}
