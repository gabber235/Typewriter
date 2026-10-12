import "package:typewriter_panel/typewriter_panel.dart";

/// Owns local intent and its lifecycle for one server transaction boundary.
/// Models describe meaning; persistence captures requests; submissions own delivery.
final class EditingWorkspace<S, E> extends ChangeNotifier {
  EditingWorkspace({
    required this.model,
    required this.persistence,
    required this.submissions,
    S? initial,
    this.scheduler = const TimerEditorDelayScheduler(),
    EditorJitterSource? jitter,
    this.debounce = const Duration(milliseconds: 250),
  }) : jitter = jitter ?? RandomEditorJitterSource(),
       _state = EditingState<S>(confirmed: initial, working: initial);

  final EditModel<S, E> model;
  EditPersistence<S, E> persistence;
  final LocalWorkCommands submissions;
  final EditorDelayScheduler scheduler;
  final EditorJitterSource jitter;
  final Duration debounce;
  EditingState<S> _state;
  EditingState<S> get state => _state;
  S get document =>
      _state.working ?? (throw StateError("Editing is not ready"));
  S get confirmed =>
      _state.confirmed ?? (throw StateError("Editing is not ready"));
  final _groups = <EditGroupId, _LiveEditGroup<S>>{};
  final _forms = <Object, EditGroupId>{};
  final _operations = <_EditOperation<S, E>>[];
  final _tasks = <EditGroupId, EditorScheduledTask>{};
  final _requested = <EditGroupId>{};
  final _interactions = <Object, EditInteraction<S, E>>{};
  var _identity = 0;
  var _revision = 0;
  var _preparations = 0;
  var _closed = false;
  var _notificationHolds = 0;
  var _notificationPending = false;
  Future<void>? _saving;
  S? _deferredConfirmed;
  bool get isPreparing => _preparations != 0;
  bool get hasPendingWork => isPreparing || _operations.isNotEmpty;
  int get revision => _revision;
  bool get closed => _closed;

  EditGroupId createGroup({
    required String label,
    Object? key,
    EditorCommitPolicy policy = EditorCommitPolicy.autosaveChanges,
    EditWriteAdmission admission = EditWriteAdmission.allowWhileSending,
    EditRepairAdmission repair = EditRepairAdmission.preserveBlockedIntent,
    EditObservationAdmission observations = EditObservationAdmission.rebase,
    EditCommitAdmission commits = EditCommitAdmission.completeGroup,
  }) {
    if (_closed) throw StateError("The editing workspace is closed");
    final id = key == null
        ? EditGroupId(++_identity)
        : _forms.putIfAbsent(key, () => EditGroupId(++_identity));
    final group = _groups.putIfAbsent(
      id,
      () => _LiveEditGroup<S>(
        id,
        policy,
        admission,
        repair,
        observations,
        commits,
        label,
      ),
    );
    if (group.policy != policy ||
        group.admission != admission ||
        group.repair != repair ||
        group.observations != observations ||
        group.commits != commits) {
      throw StateError("One editing group must retain its editing policy");
    }
    return id;
  }

  EditGroupControl<S, E> group(EditGroupId id) {
    if (!_groups.containsKey(id)) {
      throw StateError("The editing group is unavailable");
    }
    return EditGroupControl(this, id);
  }

  bool canEdit(EditGroupId id) {
    final group = _groups[id];
    return !_closed &&
        _state.available &&
        _state.working != null &&
        _state.confirmed != null &&
        model.sameContract(confirmed, document) &&
        group != null &&
        (!group.phase.blocked ||
            group.phase is EditGroupCommittedAwaitingRefresh<S> ||
            group.admission == EditWriteAdmission.allowWhileSubmitted &&
                group.phase.submitted ||
            group.repair == EditRepairAdmission.acceptCorrections &&
                (group.phase is EditGroupRejected<S> ||
                    group.phase is EditGroupConflict<S> ||
                    group.phase is EditGroupRepeatedContention<S>)) &&
        !(group.admission == EditWriteAdmission.lockWhileSubmitted &&
            group.phase.submitted);
  }

  EditStageResult stage(EditGroupId id, E edit, {String? label}) {
    if (!canEdit(id)) {
      return const EditStageResult.rejected("The editor is unavailable", null);
    }
    final replay = model.replay(document, edit);
    if (replay.kind == EditReplayKind.satisfied) {
      return const EditStageResult.unchanged();
    }
    if (replay.kind != EditReplayKind.applicable) {
      return EditStageResult.rejected(
        replay.diagnostics.firstOrNull?.message ??
            "Values changed while the edit was prepared",
        replay.cause,
      );
    }
    final owner = _groups[id]!;
    if (label != null) owner.label = label;
    if (owner.phase is EditGroupRejected<S> ||
        owner.phase is EditGroupRepeatedContention<S>) {
      owner.phase = const EditGroupPhase.dirty();
    }
    final operation = _EditOperation<S, E>(
      ++_identity,
      id,
      replay.edit,
      document,
      replay.observation,
    );
    if (_dependencies(
      operation,
      _operations,
    ).any((dependency) => _dependsOn(dependency, id, {}))) {
      return const EditStageResult.rejected(
        "This edit would create a dependency cycle",
        null,
      );
    }
    _operations.add(operation);
    _rebuild();
    if (owner.policy == EditorCommitPolicy.autosaveChanges) _schedule(id);
    return EditStageResult.staged(id);
  }

  /// Captures an observation before asynchronous preparation and admits its
  /// semantic reads against current work when preparation completes.
  Future<EditStageResult> prepare(
    EditGroupId id,
    Future<E> Function(S) prepare, {
    S? from,
    String? label,
  }) async {
    if (!canEdit(id)) {
      return const EditStageResult.rejected("The editor is unavailable", null);
    }
    final observation = from ?? document;
    _preparations++;
    _notify();
    try {
      final edit = await prepare(observation);
      if (!canEdit(id) || !model.sameContract(observation, document)) {
        return const EditStageResult.rejected(
          "The editing operation is unavailable",
          null,
        );
      }
      return stage(id, edit, label: label);
    } on Object catch (error) {
      return EditStageResult.rejected(error.toString(), error);
    } finally {
      _preparations--;
      _notify();
    }
  }

  Set<EditGroupId> _dependencies(
    _EditOperation<S, E> operation,
    Iterable<_EditOperation<S, E>> predecessors,
  ) {
    final result = <EditGroupId>{};
    final baseline = _state.confirmed;
    if (baseline == null) return result;
    final previous = predecessors.toList(growable: false);
    for (final fact in model.reads(operation.edit)) {
      if (fact.matches(baseline)) continue;
      for (final predecessor in previous.reversed) {
        if (!fact.differs(predecessor.before, predecessor.after)) continue;
        if (predecessor.group != operation.group) result.add(predecessor.group);
        break;
      }
    }
    return result;
  }

  bool _dependsOn(
    EditGroupId current,
    EditGroupId target,
    Set<EditGroupId> visited,
  ) {
    if (current == target) return true;
    if (!visited.add(current)) return false;
    return _groupDependencies(current)
        .any((other) => _dependsOn(other, target, visited));
  }

  Set<EditGroupId> _groupDependencies(EditGroupId id) {
    final previous = <_EditOperation<S, E>>[];
    final result = <EditGroupId>{};
    for (final operation in _operations) {
      if (operation.group == id) {
        result.addAll(_dependencies(operation, previous));
      }
      previous.add(operation);
    }
    return result;
  }

  void acceptConfirmed(S observation) {
    if (_closed) return;
    if (_saving != null && model.isAvailable(observation)) {
      _deferredConfirmed = observation;
      return;
    }
    _install(observation);
    final ready = _requested.firstWhereOrNull(
      (id) => _groups[id]?.phase is EditGroupDirty<S>,
    );
    if (ready != null) unawaited(save(ready));
  }

  void _install(S incoming) {
    var observation = incoming;
    final known = _state.confirmed;
    if (known != null) {
      final admission = model.acceptObservation(known, observation);
      if (admission.kind == EditObservationKind.stale) return;
      if (admission.kind == EditObservationKind.inconsistent) {
        _state = _state.copyWith(confirmed: observation);
        acceptFailure(
          StateError(admission.message ?? "Inconsistent confirmed observation"),
        );
        for (final group in _groups.values) {
          if (!group.phase.submitted) {
            group.phase = EditGroupPhase.conflict(
              admission.message ?? "Inconsistent observation",
              null,
              null,
            );
          }
        }
        _rebuild();
        return;
      }
      observation = admission.observation;
    }
    if (identical(observation, known) && _state.failure == null) return;
    _state = _state.copyWith(
      confirmed: observation,
      failure: null,
      available: true,
    );
    _rebuild();
  }

  void acceptUnavailable(Object error) {
    if (_closed) return;
    _state = _state.copyWith(available: false, failure: error);
    _notify();
  }

  void acceptFailure(Object error) {
    if (_closed) return;
    _state = _state.copyWith(failure: error);
    _notify();
  }

  void _rebuild() {
    final baseline = _state.confirmed;
    if (baseline == null || _closed) return;
    if (_operations.isNotEmpty &&
        _state.working != null &&
        !model.sameContract(baseline, document)) {
      for (final group in _groups.values) {
        if (!group.phase.submitted) {
          group.phase = const EditGroupPhase.contractChanged();
        }
      }
      _state = _state.copyWith(
        groups: {
          for (final entry in _state.groups.entries)
            entry.key: entry.value.copyWith(phase: _groups[entry.key]!.phase),
        },
      );
      _notify();
      return;
    }
    var working = baseline;
    final satisfied = <int>{};
    for (final operation in _operations) {
      final group = _groups[operation.group]!;
      final replay = model.replay(working, operation.edit);
      if (replay.kind == EditReplayKind.satisfied && group.frozen.isEmpty) {
        satisfied.add(operation.id);
        continue;
      }
      if (!group.phase.submitted && !group.phase.blocked) {
        group.phase = switch (replay.kind) {
          EditReplayKind.applicable ||
          EditReplayKind.satisfied => const EditGroupPhase.dirty(),
          EditReplayKind.conflict => EditGroupPhase.conflict(
            replay.diagnostics.firstOrNull?.message ??
                "Values changed before applying this edit",
            replay.expected,
            replay.actual,
          ),
          EditReplayKind.invalid => EditGroupPhase.rejected(
            replay.diagnostics.firstOrNull?.message ??
                "This edit cannot be applied",
            replay.cause,
          ),
          EditReplayKind.contractChanged =>
            const EditGroupPhase.contractChanged(),
          EditReplayKind.resourceMissing => EditGroupPhase.resourceMissing(
            replay.missing!,
            operation.after,
          ),
        };
      }
      if (replay.kind == EditReplayKind.contractChanged ||
          replay.kind == EditReplayKind.resourceMissing ||
          replay.kind == EditReplayKind.invalid) {
        continue;
      }
      operation
        ..before = working
        ..after = replay.observation;
      if (replay.kind == EditReplayKind.applicable && group.frozen.isEmpty) {
        operation.edit = replay.edit;
      }
      working = replay.observation;
    }
    _operations.removeWhere((operation) => satisfied.contains(operation.id));
    if (_operations.isNotEmpty &&
        !_groups.values.any(
          (group) =>
              group.frozen.isNotEmpty ||
              _groupDependencies(group.id).isNotEmpty,
        ) &&
        !model.hasEffect(
          baseline,
          _operations.map((operation) => operation.edit).toList(),
        )) {
      _operations.clear();
      working = baseline;
    }
    for (final group in _groups.values) {
      if (!group.phase.blocked && group.phase is! EditGroupSaving<S>) {
        final dependencies = _groupDependencies(group.id);
        group.phase = dependencies.isEmpty
            ? const EditGroupPhase.dirty()
            : EditGroupPhase.awaitingDependency(dependencies);
      }
    }
    final snapshots = <EditGroupId, EditGroup<S>>{};
    for (final group in _groups.values) {
      final operations = _operations
          .where((operation) => operation.group == group.id)
          .toList();
      if (operations.isEmpty) continue;
      snapshots[group.id] = EditGroup(
        id: group.id,
        label: group.label,
        policy: group.policy,
        phase: group.phase,
        operationCount: operations.length,
        original: operations.first.original,
        resources: {
          for (final operation in operations)
            ...model.resources(operation.before, operation.after),
        },
      );
    }
    for (final id in _tasks.keys.toList()) {
      if (!_canCapture(id)) _tasks.remove(id)?.cancel();
    }
    _state = _state.copyWith(
      working: model.publish(working, ++_revision),
      groups: snapshots,
    );
    _notify();
  }

  void _schedule(EditGroupId id, {Duration? delay}) {
    _tasks.remove(id)?.cancel();
    if (!_hasAdmissibleOperations(id)) return;
    final task = scheduler.schedule(delay ?? debounce);
    _tasks[id] = task;
    task.completed.then((result) {
      if (_closed ||
          result != EditorTaskCompletion.executed ||
          !identical(_tasks[id], task)) {
        return;
      }
      _tasks.remove(id);
      unawaited(save(id));
    });
  }

  Future<void> save(EditGroupId id) {
    if (_closed) return Future.value();
    _tasks.remove(id)?.cancel();
    _requested.add(id);
    return _saving ??= _drain().whenComplete(() {
      _saving = null;
      final deferred = _deferredConfirmed;
      _deferredConfirmed = null;
      if (deferred != null) acceptConfirmed(deferred);
    });
  }

  Future<void> _drain() async {
    await Future<void>.value();
    while (!_closed) {
      final id = _requested.firstWhereOrNull(
        (id) =>
            _operations.any((operation) => operation.group == id) &&
            _canCapture(id),
      );
      if (id == null) return;
      _requested.remove(id);
      await _submit(_groups[id]!);
    }
  }

  EditApplyRequest applyRequest(EditGroupId id) =>
      _WorkspaceApplyRequest<S, E>(this, id);

  Future<void> _submit(_LiveEditGroup<S> group) => const EditApplyCoordinator()
      .apply([_WorkspaceApplyRequest<S, E>(this, group.id, laneOwned: true)]);

  WorkLease? _claimLane() {
    if (_saving != null) return null;
    final completion = Completer<void>();
    _saving = completion.future;
    return WorkLease(() {
      if (!_closed && identical(_saving, completion.future)) {
        _saving = null;
        final deferred = _deferredConfirmed;
        _deferredConfirmed = null;
        if (deferred != null) acceptConfirmed(deferred);
        final ready = _requested.firstWhereOrNull(
          (id) => _groups[id]?.phase is EditGroupDirty<S>,
        );
        if (ready != null) unawaited(save(ready));
      }
      completion.complete();
    });
  }

  _WorkspacePreparedApply<S, E>? _captureApply(EditGroupId id) {
    final group = _groups[id]!;
    final current = _operations
        .where((operation) => operation.group == id)
        .toList();
    if (current.isEmpty) return null;
    if (!_canCapture(id)) throw EditPreparationFailure(group.phase.message);
    var proposed = confirmed;
    final edits = <E>[];
    final included = <int>{};
    for (final operation in current) {
      if (_gated(operation)) continue;
      final replay = model.replay(proposed, operation.edit);
      if (replay.kind != EditReplayKind.applicable &&
          replay.kind != EditReplayKind.satisfied) {
        if (group.commits == EditCommitAdmission.applicableOperations &&
            replay.kind == EditReplayKind.conflict) {
          continue;
        }
        throw EditPreparationFailure(
          replay.diagnostics.firstOrNull?.message ??
              "The values needed by this apply changed",
          replay.diagnostics,
        );
      }
      included.add(operation.id);
      proposed = replay.observation;
      edits.add(replay.edit);
    }
    final diagnostics = model.validateCommit(proposed);
    if (diagnostics.isNotEmpty) {
      throw EditPreparationFailure(diagnostics.first.message, diagnostics);
    }
    if (included.isEmpty) return null;
    final capture = EditCapture<S, E>(
      group: id,
      label: group.label,
      baseline: confirmed,
      proposed: proposed,
      edits: edits,
      operations: included,
    );
    return _WorkspacePreparedApply<S, E>(
      this,
      capture,
      persistence.prepare(capture),
    );
  }

  Future<void> _settle(
    _LiveEditGroup<S> group,
    SubmissionResult<EditSettlement<S>> result,
  ) async {
    final settlement = switch (result) {
      SubmissionConfirmed(:final value) => value,
      SubmissionRejected(response: final EditSettlement<S> response) =>
        response,
      _ => null,
    };
    if (settlement == null) {
      if (result case SubmissionNotSubmitted(:final message)) {
        group
          ..frozen = {}
          ..phase = EditGroupPhase.rejected(message, result);
      } else {
        group.phase = EditGroupPhase.uncertain(result);
      }
      _rebuild();
      return;
    }
    switch (settlement) {
      case EditConfirmed(:final observation):
        _finishCommitted(group, observation);
      case EditAccepted():
        group.phase = const EditGroupPhase.committedAwaitingRefresh(null);
        _rebuild();
        try {
          final observation = await persistence.refresh();
          if (!_closed) _finishCommitted(group, observation);
        } on Object catch (error) {
          if (!_closed) {
            group.phase = EditGroupPhase.committedAwaitingRefresh(error);
          }
        }
      case EditConflict(
        :final observation,
        :final diagnostics,
        :final expected,
        :final actual,
      ):
        group
          ..frozen = {}
          ..phase = const EditGroupPhase.dirty();
        if (observation != null) _install(observation);
        _rebuild();
        if (_canCapture(group.id)) {
          if (observation != null &&
              group.policy == EditorCommitPolicy.autosaveChanges) {
            group.attempts++;
            if (group.attempts > 3) {
              group.phase = EditGroupPhase.repeatedContention(
                group.attempts,
                expected,
                actual,
              );
            } else {
              final delay = Duration(milliseconds: 50 << (group.attempts - 1));
              final task = scheduler.schedule(
                delay +
                    jitter.next(
                      Duration(microseconds: delay.inMicroseconds ~/ 4),
                    ),
              );
              _tasks[group.id] = task;
              if (await task.completed == EditorTaskCompletion.executed &&
                  !_closed &&
                  _canCapture(group.id)) {
                _requested.add(group.id);
              }
              if (identical(_tasks[group.id], task)) _tasks.remove(group.id);
            }
          } else {
            group.phase = EditGroupPhase.conflict(
              diagnostics.firstOrNull?.message ??
                  "The server rejected the expected revision",
              expected,
              actual,
            );
          }
        }
      case EditRejected(
        :final diagnostics,
        :final cause,
        :final contractChanged,
      ):
        group
          ..frozen = {}
          ..phase = contractChanged
              ? const EditGroupPhase.contractChanged()
              : EditGroupPhase.rejected(
                  diagnostics.firstOrNull?.message ?? "The edit was rejected",
                  cause ??
                      EditPreparationFailure(
                        diagnostics.firstOrNull?.message ??
                            "The edit was rejected",
                        diagnostics,
                      ),
                );
    }
    _rebuild();
    if (group.phase is EditGroupDirty<S> &&
        !_requested.contains(group.id) &&
        group.policy == EditorCommitPolicy.autosaveChanges &&
        _operations.any((operation) => operation.group == group.id)) {
      _schedule(group.id);
    }
  }

  void _finishCommitted(_LiveEditGroup<S> group, S observation) {
    final latest = _deferredConfirmed ?? confirmed;
    final admission = model.acceptObservation(latest, observation);
    _deferredConfirmed = null;
    if (admission.kind == EditObservationKind.inconsistent) {
      final message = admission.message ?? "Inconsistent confirmed observation";
      final failure = EditPreparationFailure(message, [
        EditorDiagnostic(
          code: EditorDiagnosticCode.invalidValue,
          message: message,
        ),
      ]);
      group
        ..frozen = {}
        ..phase = EditGroupPhase.rejected(message, failure);
      _state = _state.copyWith(confirmed: latest, failure: failure);
      _rebuild();
      return;
    }
    _operations.removeWhere((operation) => group.frozen.contains(operation.id));
    group
      ..frozen = {}
      ..phase = const EditGroupPhase.dirty()
      ..attempts = 0;
    _install(admission.observation);
    _rebuild();
  }

  Future<void> refreshConfirmed() async {
    if (_closed || _saving != null) return;
    try {
      final observation = await persistence.refresh();
      if (_closed) return;
      for (final group in _groups.values) {
        if (group.phase is EditGroupCommittedAwaitingRefresh<S>) {
          _operations.removeWhere(
            (operation) => group.frozen.contains(operation.id),
          );
          group
            ..frozen = {}
            ..phase = const EditGroupPhase.dirty();
        }
      }
      _install(observation);
      for (final group in _groups.values) {
        if (group.phase is EditGroupDirty<S> &&
            !_requested.contains(group.id) &&
            group.policy == EditorCommitPolicy.autosaveChanges &&
            _operations.any((operation) => operation.group == group.id)) {
          _schedule(group.id);
        }
      }
    } on Object catch (error) {
      acceptFailure(error);
    }
  }

  bool _gated(_EditOperation<S, E> operation) {
    final group = _groups[operation.group]!;
    return _interactions.values.any(
      (interaction) =>
          interaction.group == operation.group &&
          (group.commits == EditCommitAdmission.completeGroup ||
              model.overlaps(operation.edit, interaction.key)),
    );
  }

  bool _hasAdmissibleOperations(EditGroupId id) {
    if (_state.confirmed == null) return false;
    var proposed = confirmed;
    var found = false;
    for (final operation in _operations.where(
      (operation) => operation.group == id,
    )) {
      if (_gated(operation)) continue;
      final replay = model.replay(proposed, operation.edit);
      if (replay.kind == EditReplayKind.applicable) {
        proposed = replay.observation;
        found = true;
      } else if (replay.kind != EditReplayKind.satisfied &&
          _groups[id]!.commits == EditCommitAdmission.completeGroup) {
        return false;
      }
    }
    return found;
  }

  bool _canCapture(EditGroupId id) {
    final group = _groups[id];
    return !_closed &&
        _state.available &&
        group != null &&
        (group.phase is EditGroupDirty<S> ||
            group.phase is EditGroupConflict<S> &&
                group.commits == EditCommitAdmission.applicableOperations) &&
        _hasAdmissibleOperations(id);
  }

  bool canSave(EditGroupId id) =>
      _canCapture(id) ||
      !_closed &&
          _state.available &&
          _groups[id]?.phase is EditGroupAwaitingDependency<S> &&
          _operations.any((operation) => operation.group == id);
  bool canRetry(EditGroupId id) =>
      !_closed &&
      (_groups[id]?.phase is EditGroupRejected<S> ||
          _groups[id]?.phase is EditGroupRepeatedContention<S> ||
          _groups[id]?.phase is EditGroupCommittedAwaitingRefresh<S> ||
          (_groups[id]?.phase is EditGroupUncertain<S> &&
              (_groups[id]?.submission?.canReplay ?? false)));
  Future<void> retry(EditGroupId id) async {
    if (!canRetry(id)) throw StateError("This work cannot be retried");
    final group = _groups[id]!;
    if (group.phase is EditGroupCommittedAwaitingRefresh<S>) {
      return refreshConfirmed();
    }
    if (group.phase is EditGroupUncertain<S>) {
      await _settle(group, await group.submission!.run());
      return;
    }
    group
      ..phase = const EditGroupPhase.dirty()
      ..attempts = 0;
    _rebuild();
    if (canSave(id)) await save(id);
  }

  bool canDiscard(EditGroupId id) =>
      _groups.containsKey(id) &&
      _operations.any(
        (operation) =>
            operation.group == id &&
            !_groups[id]!.frozen.contains(operation.id),
      );
  bool discard(EditGroupId id) {
    final group = _groups[id];
    if (group == null || !canDiscard(id)) return false;
    _tasks.remove(id)?.cancel();
    _requested.remove(id);
    _operations.removeWhere(
      (operation) =>
          operation.group == id && !group.frozen.contains(operation.id),
    );
    if (group.frozen.isEmpty) group.phase = const EditGroupPhase.dirty();
    _rebuild();
    for (final other in _requested.toList()) {
      if (_groups[other]?.phase is EditGroupDirty<S>) unawaited(save(other));
    }
    return true;
  }

  bool discardMatching(EditGroupId id, bool Function(E) matches) {
    final owner = _groups[id];
    if (_closed || owner == null) return false;
    final removed = _operations
        .where(
          (operation) =>
              operation.group == id &&
              !owner.frozen.contains(operation.id) &&
              matches(operation.edit),
        )
        .map((operation) => operation.id)
        .toSet();
    _operations.removeWhere((operation) => removed.contains(operation.id));
    if (owner.frozen.isEmpty) owner.phase = const EditGroupPhase.dirty();
    _rebuild();
    return removed.isNotEmpty;
  }

  void replacePending(
    EditGroupId id,
    E Function(S observation, E edit) replace,
  ) {
    final owner = _groups[id];
    if (_closed || owner == null || owner.frozen.isNotEmpty) return;
    for (final operation in _operations.where(
      (operation) => operation.group == id,
    )) {
      operation.edit = replace(confirmed, operation.edit);
    }
    owner.phase = const EditGroupPhase.dirty();
    _state = _state.copyWith(working: confirmed);
    _rebuild();
  }

  EditorCommitPolicy policyFor(EditGroupId id) => _groups[id]!.policy;

  bool hasWorkFor(Object resource) =>
      _state.groups.values.any((group) => group.resources.contains(resource));
  bool hasSubmittedWork(EditGroupId id) =>
      _groups[id]?.phase.submitted ?? false;
  bool hasLaterEdits(EditGroupId id) => hasSubmittedWork(id) && canDiscard(id);
  Object? submissionId(EditGroupId id) => _groups[id]?.submission?.id;
  List<E> edits(EditGroupId id) => List.unmodifiable(
    _operations
        .where((operation) => operation.group == id)
        .map((operation) => operation.edit),
  );

  EditInteraction<S, E> beginInteraction(EditGroupId id, Object key) {
    for (final interaction in _interactions.values.toList()) {
      if (interaction.key == key) interaction.close();
    }
    final interaction = EditInteraction<S, E>._(this, id, key, _identity);
    if (!canEdit(id)) {
      interaction.active = false;
      return interaction;
    }
    _tasks.remove(id)?.cancel();
    _interactions[key] = interaction;
    return interaction;
  }

  EditingStageHold holdStage() {
    final captured = _operations.map(_EditOperation<S, E>.copy).toList();
    final phases = {for (final group in _groups.values) group.id: group.phase};
    _notificationHolds++;
    return EditingStageHold(
      rollback: () {
        final frozen = _operations
            .where(
              (operation) =>
                  _groups[operation.group]!.frozen.contains(operation.id),
            )
            .toList();
        final frozenIds = frozen.map((operation) => operation.id).toSet();
        _operations
          ..clear()
          ..addAll([
            ...captured.where((operation) => !frozenIds.contains(operation.id)),
            ...frozen,
          ]);
        _operations.sort((left, right) => left.id.compareTo(right.id));
        for (final group in _groups.values) {
          if (!group.phase.submitted && phases.containsKey(group.id)) {
            group.phase = phases[group.id]!;
          }
        }
        _rebuild();
      },
      release: () {
        _notificationHolds--;
        if (_notificationHolds == 0 && _notificationPending) {
          _notificationPending = false;
          _notify();
        }
      },
    );
  }

  void _notify() {
    if (_closed) return;
    if (_notificationHolds != 0) {
      _notificationPending = true;
      return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    if (_closed) return;
    _closed = true;
    for (final task in _tasks.values) {
      task.cancel();
    }
    for (final interaction in _interactions.values.toList()) {
      interaction.close();
    }
    _tasks.clear();
    super.dispose();
  }
}

final class _LiveEditGroup<S> {
  _LiveEditGroup(
    this.id,
    this.policy,
    this.admission,
    this.repair,
    this.observations,
    this.commits,
    this.label,
  );
  final EditGroupId id;
  final EditorCommitPolicy policy;
  final EditWriteAdmission admission;
  final EditRepairAdmission repair;
  final EditObservationAdmission observations;
  final EditCommitAdmission commits;
  int attempts = 0;
  String label;
  EditGroupPhase<S> phase = const EditGroupPhase.dirty();
  Set<int> frozen = {};
  MutationSubmission<EditSettlement<S>>? submission;
}

final class _EditOperation<S, E> {
  _EditOperation(this.id, this.group, this.edit, this.before, this.after)
    : original = before;
  _EditOperation.copy(_EditOperation<S, E> other)
    : id = other.id,
      group = other.group,
      edit = other.edit,
      before = other.before,
      after = other.after,
      original = other.original;
  final int id;
  final EditGroupId group;
  E edit;
  final S original;
  S before;
  S after;
}

/// A reversible local gate. Closing a view does not discard its pending work.
final class EditInteraction<S, E> {
  EditInteraction._(this.workspace, this.group, this.key, this.start);
  final EditingWorkspace<S, E> workspace;
  final EditGroupId group;
  final Object key;
  final int start;
  bool active = true;
  bool get owned =>
      active &&
      identical(workspace._interactions[key], this) &&
      workspace.canEdit(group);
  void close() {
    if (!active) return;
    active = false;
    if (identical(workspace._interactions[key], this)) {
      workspace._interactions.remove(key);
    }
  }

  Future<void> commit() async {
    if (!owned) {
      close();
      return;
    }
    close();
    if (workspace._groups[group]!.policy ==
        EditorCommitPolicy.autosaveChanges) {
      await workspace.save(group);
    }
  }

  void cancel() {
    if (!owned) {
      close();
      return;
    }
    workspace._operations.removeWhere(
      (operation) =>
          operation.id > start &&
          operation.group == group &&
          workspace.model.overlaps(operation.edit, key) &&
          !workspace._groups[group]!.frozen.contains(operation.id),
    );
    close();
    workspace._rebuild();
  }
}

final class _WorkspaceApplyRequest<S, E> implements EditApplyRequest {
  const _WorkspaceApplyRequest(
    this.workspace,
    this.group, {
    this.laneOwned = false,
  });
  final EditingWorkspace<S, E> workspace;
  final EditGroupId group;
  final bool laneOwned;
  @override
  Object get identity => (workspace, group);
  @override
  Object get lane => workspace;
  @override
  LocalWorkCommands get submissions => workspace.submissions;
  @override
  Future<void> get idle =>
      laneOwned ? Future.value() : workspace._saving ?? Future.value();
  @override
  WorkLease? claim() => laneOwned ? WorkLease(() {}) : workspace._claimLane();
  @override
  EditingStageHold holdStage() => workspace.holdStage();
  @override
  Set<Object> get reservations =>
      workspace.persistence.reservationsFor(workspace.edits(group));
  @override
  Future<void> observe() async {
    final known = workspace.confirmed;
    final observation = await workspace.persistence.observeForCommit(known);
    if (workspace._closed) {
      throw const EditPreparationFailure("The editing workspace closed");
    }
    final admission = workspace.model.acceptObservation(known, observation);
    workspace._install(observation);
    if (workspace._groups[group]!.observations ==
            EditObservationAdmission.reviewChanges &&
        admission.changed &&
        workspace.edits(group).isNotEmpty) {
      workspace._groups[group]!.phase = const EditGroupPhase.conflict(
        "The authoritative resource changed while preparing this apply",
        null,
        null,
      );
      throw const EditPreparationFailure(
        "The authoritative resource changed while preparing this apply",
      );
    }
  }

  @override
  EditPreparedApply? capture() => workspace._captureApply(group);
  @override
  void reject(Object cause) {
    if (workspace._closed) return;
    final owner = workspace._groups[group]!;
    if (!owner.phase.blocked && owner.frozen.isEmpty) {
      owner.phase = EditGroupPhase.rejected(
        cause is EditPreparationFailure
            ? cause.message
            : "Preparing changes failed (${cause.runtimeType})",
        cause,
      );
    }
    workspace._rebuild();
  }
}

final class _WorkspacePreparedApply<S, E> implements EditPreparedApply {
  const _WorkspacePreparedApply(this.workspace, this.capture, this.prepared);
  final EditingWorkspace<S, E> workspace;
  final EditCapture<S, E> capture;
  final PreparedCommit<EditSettlement<S>> prepared;
  @override
  Set<Object> get resources => prepared.resources;
  @override
  Future<void> start(MutationReservation reservation) async {
    final group = workspace._groups[capture.group]!
      ..frozen = capture.operations
      ..phase = const EditGroupPhase.saving();
    workspace._rebuild();
    MutationSubmission<EditSettlement<S>> submission;
    try {
      submission = workspace.submissions.start(
        prepared,
        reservation: reservation,
      );
    } on Object catch (error) {
      reservation.release();
      if (!workspace._closed) {
        group
          ..frozen = {}
          ..phase = EditGroupPhase.rejected(
            "The edit was not submitted",
            error,
          );
        workspace._rebuild();
      }
      return;
    }
    group.submission = submission;
    final result = await submission.run();
    if (!workspace._closed) await workspace._settle(group, result);
  }
}
