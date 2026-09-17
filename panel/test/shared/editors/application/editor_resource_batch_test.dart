import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

EditorSnapshot _snapshot() => const DocumentEditorSnapshot(
  EditorDocument(
    rootType: StringType(),
    typeCatalog: TypeCatalog([]),
    confirmedValue: StringValue("Original"),
    revision: 1,
  ),
);

typedef _Operation = (EditorResourceKey, EditorCommit);

final class _BatchResource implements EditableResource {
  _BatchResource(String id, this.combiner)
    : key = EditorResourceKey(scope: "realm", identity: id);
  final MutationCombiner<_Operation, List<_Operation>> combiner;

  @override
  final EditorResourceKey key;

  @override
  Set<Object> get reservations => {key};
  int reads = 0;
  bool unavailable = false;
  Completer<void>? refreshStarted;
  Future<void>? refreshBarrier;

  @override
  Future<EditorSnapshot?> refresh() async {
    reads++;
    refreshStarted?.complete();
    if (refreshBarrier case final barrier?) await barrier;
    if (unavailable) throw StateError("Unavailable");
    return _snapshot();
  }

  @override
  MutationIntent prepare(
    EditorSnapshot snapshot,
    EditorCommit commit,
    void Function(TypedMutationResult) accept,
  ) => CombinedMutation<_Operation, List<_Operation>>(
    combiner: combiner,
    resources: reservations,
    prepare: () => MutationContribution(
      operation: (key, commit),
      integrate: (result) async {
        switch (result) {
          case SubmissionConfirmed():
            accept(MutationSuccess(revision: 2, value: commit.rootValue));
          case SubmissionRejected(:final message):
            accept(
              MutationUnavailable([
                TypeDiagnostic(
                  code: TypeDiagnosticCode.invalidValue,
                  message: message,
                ),
              ]),
            );
          default:
            break;
        }
      },
    ),
  );
}

TransactionalEditorSource _source(
  LocalWorkSession workspace,
  _BatchResource resource, {
  EditorCommitPolicy commitPolicy = EditorCommitPolicy.applyResource,
}) {
  final source = workspace.editor(
    ResourceEditorTarget(
      targetId: resource.key.identity,
      label: "Resource",
      resource: resource,
      snapshot: _snapshot(),
      commitPolicy: commitPolicy,
    ),
  ) as TransactionalEditorSource;
  workspace.retain(resource.key);
  return source;
}

void main() {
  test("resource batch publishes accepted drafts before refresh", () async {
    final workspace = LocalWorkSession();
    addTearDown(workspace.dispose);
    final refreshStarted = Completer<void>();
    final refreshBarrier = Completer<void>();
    final combiner = MutationCombiner<_Operation, List<_Operation>>(
      prepare: (operations) => PreparedCommit(
        id: Object(),
        label: "Batch",
        resources: operations.map((operation) => operation.$1).toSet(),
        send: () async => SubmissionConfirmed(operations),
      ),
    );
    final resource = _BatchResource("first", combiner)
      ..refreshStarted = refreshStarted
      ..refreshBarrier = refreshBarrier.future;
    final source = _source(workspace, resource);

    final batch = EditorBatch.submit(
      changes: {
        source: {DataPath.root: const StringValue("Draft")},
      },
    );
    await refreshStarted.future;

    final projected = workspace.state.editorValues[resource.key];
    expect(projected?.value, const StringValue("Draft"));
    expect(projected?.editedPaths, {DataPath.root});

    refreshBarrier.complete();
    expect((await batch).values, everyElement(isA<MutationSuccess>()));
    expect(workspace.state.editorValues, isEmpty);
  });

  test(
    "multi interaction sends one batch for every selected resource",
    () async {
      final workspace = LocalWorkSession();
      addTearDown(workspace.dispose);
      final requests = <List<_Operation>>[];
      final combiner = MutationCombiner<_Operation, List<_Operation>>(
        prepare: (operations) => PreparedCommit(
          id: Object(),
          label: "Batch",
          resources: operations.map((operation) => operation.$1).toSet(),
          send: () async {
            requests.add(operations);
            return SubmissionConfirmed(operations);
          },
        ),
      );
      final first = _source(
        workspace,
        _BatchResource("first", combiner),
        commitPolicy: EditorCommitPolicy.autosaveChanges,
      );
      final second = _source(
        workspace,
        _BatchResource("second", combiner),
        commitPolicy: EditorCommitPolicy.autosaveChanges,
      );
      final owner = MultiEditOwner(
        owners: [first, second],
        rootType: const StringType(),
        typeCatalog: const TypeCatalog([]),
        commitInteractions: (interactions) => interactions.commitAtomically(),
      );
      addTearDown(owner.dispose);

      final interaction = owner.beginInteraction(DataPath.root);
      expect(
        owner.update(DataPath.root, const StringValue("Shared")),
        isA<AppliedEditorMutation>(),
      );
      await interaction.commit();

      expect(requests, hasLength(1));
      expect(requests.single, hasLength(2));
      expect(
        requests.single.map((operation) => operation.$2.rootValue),
        everyElement(const StringValue("Shared")),
      );
      expect(first.hasWork, isFalse);
      expect(second.hasWork, isFalse);
    },
  );

  test("rejected multi interaction retry does not replay mutations", () async {
    final workspace = LocalWorkSession();
    addTearDown(workspace.dispose);
    final requests = <List<_Operation>>[];
    var reject = true;
    final combiner = MutationCombiner<_Operation, List<_Operation>>(
      prepare: (operations) => PreparedCommit(
        id: Object(),
        label: "Batch",
        resources: operations.map((operation) => operation.$1).toSet(),
        send: () async {
          requests.add(operations);
          return reject
              ? const SubmissionRejected(message: "Try again")
              : SubmissionConfirmed(operations);
        },
      ),
    );
    final first = _source(
      workspace,
      _BatchResource("first", combiner),
      commitPolicy: EditorCommitPolicy.autosaveChanges,
    );
    final second = _source(
      workspace,
      _BatchResource("second", combiner),
      commitPolicy: EditorCommitPolicy.autosaveChanges,
    );
    final owner = MultiEditOwner(
      owners: [first, second],
      rootType: const StringType(),
      typeCatalog: const TypeCatalog([]),
      commitInteractions: (interactions) => interactions.commitAtomically(),
    );
    addTearDown(owner.dispose);

    final interaction = owner.beginInteraction(DataPath.root);
    owner.update(DataPath.root, const StringValue("Shared"));
    await interaction.commit();
    final rejected = requests.single;

    reject = false;
    await second.flush();

    expect(requests, hasLength(2));
    for (var index = 0; index < rejected.length; index++) {
      expect(
        requests.last[index].$2.localRevision,
        rejected[index].$2.localRevision,
      );
      expect(requests.last[index].$2.mutations, rejected[index].$2.mutations);
    }
  });

  test("apply resource interaction releases gates without saving", () async {
    final workspace = LocalWorkSession();
    addTearDown(workspace.dispose);
    final requests = <List<_Operation>>[];
    final combiner = MutationCombiner<_Operation, List<_Operation>>(
      prepare: (operations) => PreparedCommit(
        id: Object(),
        label: "Batch",
        resources: operations.map((operation) => operation.$1).toSet(),
        send: () async {
          requests.add(operations);
          return SubmissionConfirmed(operations);
        },
      ),
    );
    final first = _source(workspace, _BatchResource("first", combiner));
    final second = _source(workspace, _BatchResource("second", combiner));
    final owner = MultiEditOwner(
      owners: [first, second],
      rootType: const StringType(),
      typeCatalog: const TypeCatalog([]),
      commitInteractions: (interactions) => interactions.commitAtomically(),
    );
    addTearDown(owner.dispose);

    final interaction = owner.beginInteraction(DataPath.root);
    owner.update(DataPath.root, const StringValue("Shared"));
    await interaction.commit();

    expect(interaction.active, isFalse);
    expect(requests, isEmpty);
    expect(first.hasWork, isTrue);
    expect(second.hasWork, isTrue);
  });

  test("cancelling a multi interaction restores every draft", () async {
    final workspace = LocalWorkSession();
    addTearDown(workspace.dispose);
    final requests = <List<_Operation>>[];
    final combiner = MutationCombiner<_Operation, List<_Operation>>(
      prepare: (operations) => PreparedCommit(
        id: Object(),
        label: "Batch",
        resources: operations.map((operation) => operation.$1).toSet(),
        send: () async {
          requests.add(operations);
          return SubmissionConfirmed(operations);
        },
      ),
    );
    final first = _source(
      workspace,
      _BatchResource("first", combiner),
      commitPolicy: EditorCommitPolicy.autosaveChanges,
    );
    final second = _source(
      workspace,
      _BatchResource("second", combiner),
      commitPolicy: EditorCommitPolicy.autosaveChanges,
    );
    final owner = MultiEditOwner(
      owners: [first, second],
      rootType: const StringType(),
      typeCatalog: const TypeCatalog([]),
      commitInteractions: (interactions) => interactions.commitAtomically(),
    );
    addTearDown(owner.dispose);

    final interaction = owner.beginInteraction(DataPath.root);
    owner.update(DataPath.root, const StringValue("Shared"));
    interaction.cancel();

    expect(interaction.active, isFalse);
    expect(requests, isEmpty);
    expect(
      first.value(DataPath.root).valueOrNull,
      const StringValue("Original"),
    );
    expect(
      second.value(DataPath.root).valueOrNull,
      const StringValue("Original"),
    );
    expect(first.hasWork, isFalse);
    expect(second.hasWork, isFalse);
  });

  test(
    "partially closed atomic cohort cancels every remaining member",
    () async {
      final workspace = LocalWorkSession();
      addTearDown(workspace.dispose);
      final requests = <List<_Operation>>[];
      final combiner = MutationCombiner<_Operation, List<_Operation>>(
        prepare: (operations) => PreparedCommit(
          id: Object(),
          label: "Batch",
          resources: operations.map((operation) => operation.$1).toSet(),
          send: () async {
            requests.add(operations);
            return SubmissionConfirmed(operations);
          },
        ),
      );
      final first = _source(
        workspace,
        _BatchResource("first", combiner),
        commitPolicy: EditorCommitPolicy.autosaveChanges,
      );
      final second = _source(
        workspace,
        _BatchResource("second", combiner),
        commitPolicy: EditorCommitPolicy.autosaveChanges,
      );
      final firstInteraction = first.beginInteraction(DataPath.root);
      final secondInteraction = second.beginInteraction(DataPath.root);
      first.update(DataPath.root, const StringValue("First"));
      second.update(DataPath.root, const StringValue("Second"));
      firstInteraction.cancel();

      await [firstInteraction, secondInteraction].commitAtomically();

      expect(requests, isEmpty);
      expect(
        first.value(DataPath.root).valueOrNull,
        const StringValue("Original"),
      );
      expect(
        second.value(DataPath.root).valueOrNull,
        const StringValue("Original"),
      );
      expect(secondInteraction.active, isFalse);
    },
  );

  test("atomic commit rejects duplicate resource interactions", () async {
    final workspace = LocalWorkSession();
    addTearDown(workspace.dispose);
    final combiner = MutationCombiner<_Operation, List<_Operation>>(
      prepare: (operations) => PreparedCommit(
        id: Object(),
        label: "Batch",
        resources: operations.map((operation) => operation.$1).toSet(),
        send: () async => SubmissionConfirmed(operations),
      ),
    );
    final source = _source(
      workspace,
      _BatchResource("first", combiner),
      commitPolicy: EditorCommitPolicy.autosaveChanges,
    );
    final interaction = source.beginInteraction(DataPath.root);
    addTearDown(interaction.cancel);

    await expectLater(
      [interaction, interaction].commitAtomically(),
      throwsStateError,
    );
  });

  for (final failRefresh in [true, false]) {
    test(
      "retrying one member preserves the complete batch after ${failRefresh ? "refresh failure" : "rejection"}",
      () async {
        final workspace = LocalWorkSession();
        addTearDown(workspace.dispose);
        final requests = <List<_Operation>>[];
        var reject = !failRefresh;
        final combiner = MutationCombiner<_Operation, List<_Operation>>(
          prepare: (operations) => PreparedCommit(
            id: Object(),
            label: "Batch",
            resources: operations.map((operation) => operation.$1).toSet(),
            send: () async {
              requests.add(operations);
              if (reject) return const SubmissionRejected(message: "Try again");
              return SubmissionConfirmed(operations);
            },
          ),
        );
        final firstResource = _BatchResource("first", combiner);

        final secondResource = _BatchResource("second", combiner)
          ..unavailable = failRefresh;
        final first = _source(workspace, firstResource);
        final second = _source(workspace, secondResource);
        final result = await EditorBatch.submit(
          changes: {
            first: {DataPath.root: const StringValue("First")},
            second: {DataPath.root: const StringValue("Second")},
          },
        );
        expect(result.values, everyElement(isA<MutationUnavailable>()));
        expect(requests, hasLength(failRefresh ? 0 : 1));

        expect(first.hasWork, isTrue);
        expect(second.hasWork, isTrue);

        secondResource.unavailable = false;
        reject = false;
        expect(await first.flush(), isA<MutationSuccess>());
        expect(requests.last.map((operation) => operation.$1), [
          firstResource.key,
          secondResource.key,
        ]);
        expect(requests.last.map((operation) => operation.$2.rootValue), [
          const StringValue("First"),
          const StringValue("Second"),
        ]);
        expect(firstResource.reads, 2);

        expect(secondResource.reads, 2);
        expect(first.hasWork, isFalse);
        expect(second.hasWork, isFalse);
      },
    );
  }

  test(
    "one uncertain batch replays the same request and settles every member",
    () async {
      final workspace = LocalWorkSession();
      addTearDown(workspace.dispose);
      final requests = <List<_Operation>>[];
      final combiner = MutationCombiner<_Operation, List<_Operation>>(
        prepare: (operations) => PreparedCommit(
          id: Object(),
          label: "Batch",
          resources: operations.map((operation) => operation.$1).toSet(),
          replay: SubmissionReplay.identicalRequest,
          send: () async {
            requests.add(operations);
            if (requests.length == 1) {
              return SubmissionUncertain(
                message: "Lost response",
                cause: StateError("Lost response"),
                stackTrace: StackTrace.current,
              );
            }
            return SubmissionConfirmed(operations);
          },
        ),
      );
      final firstResource = _BatchResource("first", combiner);
      final secondResource = _BatchResource("second", combiner);

      final first = _source(workspace, firstResource);
      final second = _source(workspace, secondResource);
      final result = await EditorBatch.submit(
        changes: {
          first: {DataPath.root: const StringValue("First")},
          second: {DataPath.root: const StringValue("Second")},
        },
      );
      expect(result.values, everyElement(isA<MutationUncertain>()));
      expect(await second.flush(), isA<MutationSuccess>());
      expect(requests, hasLength(2));

      expect(requests.last, same(requests.first));
      expect(firstResource.reads, 1);
      expect(secondResource.reads, 1);
      expect(first.hasWork, isFalse);
      expect(second.hasWork, isFalse);
    },
  );
}
