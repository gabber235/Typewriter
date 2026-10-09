part of "transactional_editor_source.dart";

extension _EditorInteractions on TransactionalEditorSource {
  void _cancelDebounce() {
    _debounceTask?.cancel();
    _debounceTask = null;
  }

  void _cancelScheduledTasks() {
    _cancelDebounce();
    _retryTask?.cancel();
    _retryTask = null;
  }

  Future<TypedMutationResult> _commitInteraction(_Interaction interaction) {
    if (!_release(interaction)) {
      return Future.value(_unavailable("Interaction is closed"));
    }
    if (commitPolicy == EditorCommitPolicy.applyResource) {
      return Future.value(_settledResult());
    }
    return flush(paths: {..._states.autoFlushCandidates, interaction.path});
  }

  void _discardDraft() {
    if (_disposed || _activeCommit != null || _unresolved != null) return;
    _cancelScheduledTasks();
    _closeGates();
    _draft = _document.confirmedValue;

    _rejectedBatch = null;

    _pendingMutations.clear();
    for (final path in _states.dirtyPaths) {
      _states.reset(path);
    }
    _notify();
  }

  void _cancelInteraction(_Interaction interaction) {
    if (!_release(interaction)) return;
    if (_disposed || _deleted) return;
    final origin = interaction.origin;
    if (origin != null) {
      _draft = _draft.replacingEditorValue(interaction.path, origin) ?? _draft;
    }
    _pendingMutations.removeWhere(
      (pending) =>
          pending.revision > interaction.startingRevision &&
          _pathsOverlap(interaction.path, pending.mutation.path),
    );

    _states.reset(interaction.path);
    _notify();
  }

  bool _release(_Interaction interaction) {
    if (!interaction.active) return false;
    interaction.close();
    _states.clearGate(interaction.path, interaction);
    return true;
  }

  void _closeGates() {
    for (final gate in _states.takeGates()) {
      if (gate is _Interaction) gate.close();
    }
  }
}

/// Commits one resource interaction per source through one atomic batch.
///
/// Every interaction gate remains closed until this operation owns settlement
/// for the complete cohort. Inactive cohorts settle without persistence.
extension AtomicResourceInteractionCommit
    on Iterable<EditorInteractionSession> {
  Future<void> commitAtomically() async {
    final sessions = toList(growable: false);
    final interactions = sessions.whereType<_Interaction>().toList();
    if (sessions.isEmpty || interactions.length != sessions.length) {
      throw StateError(
        "Atomic interaction commit requires resource editor interactions",
      );
    }
    final sources = interactions.map((interaction) => interaction.source);
    if ((Set<TransactionalEditorSource>.identity()..addAll(sources)).length !=
        interactions.length) {
      throw StateError("Atomic interaction sources must be identity unique");
    }
    if (interactions.any(
      (interaction) => interaction.source.resource == null,
    )) {
      throw StateError("Atomic interaction commit requires resources");
    }
    final workspace = interactions.first.source.workspace;
    if (workspace == null ||
        interactions.any(
          (interaction) => interaction.source.workspace != workspace,
        )) {
      throw StateError("Atomic interactions must belong to one workspace");
    }
    final policy = interactions.first.source.commitPolicy;
    if (interactions.any(
      (interaction) => interaction.source.commitPolicy != policy,
    )) {
      throw StateError("Atomic interactions must share one commit policy");
    }

    if (interactions.every((interaction) => !interaction.active)) return;
    if (interactions.any((interaction) => !interaction.active)) {
      for (final interaction in interactions.where(
        (interaction) => interaction.active,
      )) {
        interaction.cancel();
      }
      return;
    }

    while (interactions.any(
      (interaction) => interaction.source._activeCommit != null,
    )) {
      await Future.wait([
        for (final interaction in interactions)
          ?interaction.source._activeCommit,
      ]);
    }
    final stillOwned = interactions.every(
      (interaction) =>
          interaction.active &&
          identical(
            interaction.source._states.gate(interaction.path),
            interaction,
          ),
    );
    if (!stillOwned) {
      for (final interaction in interactions.where(
        (interaction) => interaction.active,
      )) {
        interaction.cancel();
      }
      return;
    }

    final paths = {
      for (final interaction in interactions)
        interaction.source: {
          ...interaction.source._states.autoFlushCandidates,
          interaction.path,
        },
    };
    final completions = EditorBatch._claim(paths.keys);
    for (final interaction in interactions) {
      interaction.source._release(interaction);
    }
    if (policy == EditorCommitPolicy.applyResource) {
      EditorBatch._completeClaim(completions, {
        for (final source in paths.keys) source: source._settledResult(),
      });
      return;
    }
    await EditorBatch._flushPreparedClaimed(paths, completions);
  }
}

final class _Interaction implements EditorInteractionSession {
  _Interaction({
    required this.source,
    required this.path,
    required this.origin,
    required this.startingRevision,
  });

  final TransactionalEditorSource source;

  @override
  final skir.ValuePath path;
  final skir.DataValue? origin;
  final int startingRevision;

  @override
  bool active = true;

  @override
  Future<void> commit() async {
    await source._commitInteraction(this);
  }

  @override
  void cancel() => source._cancelInteraction(this);

  void close() => active = false;
}

EditorDiagnostic _diagnostic(String message, [skir.ValuePath? at]) {
  return EditorDiagnostic(
    code: EditorDiagnosticCode.mutationConflict,
    message: message,
    path: at ?? editorRootPath,
  );
}

EditorDiagnostic _deletedDiagnostic() => _diagnostic("Deleted elsewhere");

TypedMutationResult _unavailable(String message) =>
    TypedMutationResult.unavailable([_diagnostic(message)]);

bool _targetWasDeleted(List<EditorDiagnostic> diagnostics) {
  return diagnostics.any(
    (diagnostic) => diagnostic.details["editor.target"] == "deleted",
  );
}

final class _PendingStructuralMutation {
  const _PendingStructuralMutation(this.revision, this.mutation);

  final int revision;
  final EditorStructuralMutation mutation;
}

bool _pathsOverlap(skir.ValuePath first, skir.ValuePath second) {
  final shared = first.segments.length < second.segments.length
      ? first.segments.length
      : second.segments.length;
  for (var index = 0; index < shared; index++) {
    if (first.segments.elementAt(index) != second.segments.elementAt(index)) {
      return false;
    }
  }
  return true;
}

const _retryDelays = [
  Duration(milliseconds: 50),
  Duration(milliseconds: 100),
  Duration(milliseconds: 200),
];

final class _UnresolvedCommit {
  const _UnresolvedCommit(this.commit, this.result);
  final EditorCommit commit;
  final MutationUncertain result;
}
