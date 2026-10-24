import "package:typewriter_panel/typewriter_panel.dart";

enum EditGroupLifetime { reusable, operation }

/// Owns the ordered local edit journal for one persistence boundary.
///
/// [model] interprets observations and replays semantic edits. Confirmed state
/// comes from that boundary; working state is derived by replaying the journal
/// over it. Groups give related edits a save policy and recovery state while
/// preserving dependencies on earlier local facts.
///
/// Saving reserves resources, refreshes the baseline, and asks [persistence] to
/// capture one immutable request. [submissions] owns delivery. Captured operation
/// identities remain frozen until settlement so later edits survive that save.
/// Unknown outcomes retain their captured work for explicit recovery. The
/// creating caller or registering work driver disposes this workspace and its
/// scheduled interactions.
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
  bool get applying => _saving != null;

  /// Creates a save group, or reuses the group associated with [key].
  /// Reusing a key requires identical editing policies; labels may be updated
  /// by later staged operations.
  EditGroupId createGroup({
    required String label,
    Object? key,
    EditGroupLifetime lifetime = EditGroupLifetime.reusable,
    EditorCommitPolicy policy = EditorCommitPolicy.autosaveChanges,
    EditWriteAdmission admission = EditWriteAdmission.allowWhileSending,
    EditRepairAdmission repair = EditRepairAdmission.preserveBlockedIntent,
    EditObservationAdmission observations = EditObservationAdmission.rebase,
    EditCommitAdmission commits = EditCommitAdmission.completeGroup,
  }) {
    if (_closed) throw StateError("The editing workspace is closed");
    if (key != null && lifetime != EditGroupLifetime.reusable) {
      throw ArgumentError("Keyed editing groups must be reusable");
    }
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
        lifetime,
      ),
    );
    if (group.lifetime != lifetime ||
        group.policy != policy ||
        group.admission != admission ||
        group.repair != repair ||
        group.observations != observations ||
        group.commits != commits) {
      throw StateError("One editing group must retain its editing policy");
    }
    return id;
  }

  /// Releases a group that never acquired work or an active interaction.
  /// Failed preparation can allocate a group without publishing an edit.
  bool disposeEmptyGroup(EditGroupId id) {
    final group = _groups[id];
    if (_closed ||
        _saving != null ||
        _preparations != 0 ||
        _notificationHolds != 0 ||
        group == null ||
        group.controls != 0 ||
        group.phase.submitted ||
        group.frozen.isNotEmpty ||
        _operations.any((operation) => operation.group == id) ||
        _interactions.values.any((interaction) => interaction.group == id) ||
        _groups.values.any(
          (other) => _groupDependencies(other.id).contains(id),
        )) {
      return false;
    }
    _tasks.remove(id)?.cancel();
    _requested.remove(id);
    _forms.removeWhere((_, value) => value == id);
    _groups.remove(id);
    _rebuild();
    return true;
  }

  /// Retires settled independent work after its save, preparation and rollback
  /// owners release it. The submission journal retains its own feedback records.
  void retireIdleGroups() {
    if (_closed ||
        _saving != null ||
        _preparations != 0 ||
        _notificationHolds != 0) {
      return;
    }
    final referenced = {
      for (final operation in _operations) operation.group,
      for (final interaction in _interactions.values) interaction.group,
      for (final group in _groups.values) ..._groupDependencies(group.id),
    };
    for (final group in _groups.values.toList()) {
      if (group.lifetime != EditGroupLifetime.operation ||
          group.controls != 0 ||
          referenced.contains(group.id) ||
          group.frozen.isNotEmpty ||
          group.phase.submitted) {
        continue;
      }
      _tasks.remove(group.id)?.cancel();
      _requested.remove(group.id);
      _groups.remove(group.id);
    }
  }

  WorkLease retainGroup(EditGroupId id) {
    final group = _groups[id];
    if (_closed || group == null) {
      throw StateError("The editing group is unavailable");
    }
    group.controls++;
    return WorkLease(() {
      if (_closed || !identical(_groups[id], group)) return;
      group.controls--;
      retireIdleGroups();
    });
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
    if (owner.commits == EditCommitAdmission.requiredDependencies) {
      try {
        final required = _requiredOperationClosure(operation);
        final previousOwners = <EditGroupId>{};
        for (var index = 0; index < _operations.length; index++) {
          final previous = _operations[index];
          if (required.contains(previous.id) && previous.group != id) {
            previousOwners.add(previous.group);
            _operations[index] = _EditOperation.reowned(previous, id);
          }
        }
        for (final previous in previousOwners) {
          if (_operations.any((item) => item.group == previous)) continue;
          _tasks.remove(previous)?.cancel();
          _requested.remove(previous);
        }
      } on EditPreparationFailure catch (failure) {
        return EditStageResult.rejected(failure.message, failure);
      }
    } else if (_dependencies(
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
      retireIdleGroups();
    }
  }

  Set<int> _requiredOperationClosure(_EditOperation<S, E> operation) {
    final required = <int>{};
    void include(_EditOperation<S, E> current, int before) {
      for (final fact in model.reads(current.edit)) {
        if (fact.matches(confirmed)) continue;
        for (var index = before - 1; index >= 0; index--) {
          final predecessor = _operations[index];
          if (!fact.differs(predecessor.before, predecessor.after)) continue;
          if (required.add(predecessor.id)) include(predecessor, index);
        }
      }
    }

    include(operation, _operations.length);
    // An existing operation group retains its own complete pending prefix.
    for (final (index, predecessor) in _operations.indexed) {
      if (predecessor.group == operation.group &&
          required.add(predecessor.id)) {
        include(predecessor, index);
      }
    }
    var proposed = confirmed;
    for (final predecessor in _operations.where(
      (item) => required.contains(item.id),
    )) {
      final owner = _groups[predecessor.group]!;
      if (owner.phase.blocked ||
          owner.phase.submitted ||
          owner.frozen.isNotEmpty ||
          _gated(predecessor)) {
        throw const EditPreparationFailure(
          "Required draft work is blocked or still being edited. Finish or resolve it first",
        );
      }
      final replay = model.replay(proposed, predecessor.edit);
      if (replay.kind != EditReplayKind.applicable &&
          replay.kind != EditReplayKind.satisfied) {
        throw EditPreparationFailure(
          replay.diagnostics.firstOrNull?.message ??
              "Required draft facts changed",
          replay.diagnostics,
        );
      }
      proposed = replay.observation;
    }
    final replay = model.replay(proposed, operation.edit);
    if (replay.kind != EditReplayKind.applicable &&
        replay.kind != EditReplayKind.satisfied) {
      throw EditPreparationFailure(
        replay.diagnostics.firstOrNull?.message ??
            "Required draft facts changed",
        replay.diagnostics,
      );
    }
    final diagnostics = model.validateCommit(replay.observation);
    if (diagnostics.isNotEmpty) {
      throw EditPreparationFailure(diagnostics.first.message, diagnostics);
    }
    return required;
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

  /// Admits a canonical observation and rebases pending local intent.
  /// Available observations received during a save are deferred until the
  /// active lane settles, preventing them from replacing its captured baseline.
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
            replay.conflict,
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
    final previousGroups = _state.groups;
    _state = _state.copyWith(
      working: model.publish(working, ++_revision),
      groups: snapshots,
    );
    for (final group in snapshots.values) {
      if (group.policy == EditorCommitPolicy.autosaveChanges &&
          group.phase is EditGroupDirty<S> &&
          previousGroups[group.id]?.phase is EditGroupAwaitingDependency<S> &&
          !_tasks.containsKey(group.id) &&
          !_requested.contains(group.id)) {
        _schedule(group.id);
      }
    }
    _notify();
    retireIdleGroups();
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
      retireIdleGroups();
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
      retireIdleGroups();
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
      if (!group.phase.submitted && group.submission?.sending != true) {
        group.submission = null;
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
      case EditConflict(:final observation, :final evidence):
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
                evidence,
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
              evidence.diagnostics.firstOrNull?.message ??
                  "Saved values changed before this edit was applied",
              evidence,
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
    if (!group.phase.submitted && group.submission?.sending != true) {
      group.submission = null;
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
      ..attempts = 0
      ..submission = null;
    _install(admission.observation);
    _rebuild();
  }

  /// Refreshes acknowledged state without replaying a submitted request.
  /// Groups awaiting refresh release only their frozen operations after the
  /// refresh succeeds. Later edits remain in the journal.
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
            ..phase = const EditGroupPhase.dirty()
            ..submission = null;
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
          (group.commits != EditCommitAdmission.applicableOperations ||
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
          _groups[id]!.commits != EditCommitAdmission.applicableOperations) {
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

  /// Captures only unsent work. Refresh externally before taking this snapshot.
  EditGroupReview<S, E> inspectUnsubmitted(EditGroupId id) {
    final owner = _groups[id];
    final selected = _operations
        .where((operation) => operation.group == id)
        .toList();
    if (_closed ||
        !_state.available ||
        owner == null ||
        selected.isEmpty ||
        owner.frozen.isNotEmpty ||
        owner.phase.submitted) {
      throw const EditPreparationFailure("This group cannot be resolved");
    }
    var before = confirmed;
    for (final operation in _operations.takeWhile(
      (operation) => operation.group != id,
    )) {
      final replay = model.replay(before, operation.edit);
      if (replay.kind == EditReplayKind.applicable ||
          replay.kind == EditReplayKind.satisfied ||
          replay.kind == EditReplayKind.conflict) {
        before = replay.observation;
      }
    }
    var proposal = before;
    final conflicts = <EditConflictEvidence>[];
    final diagnostics = <EditorDiagnostic>[];
    var retainedProposal = false;
    for (final operation in selected) {
      final replay = model.replay(proposal, operation.edit);
      if (replay.conflict case final evidence?) {
        conflicts.add(evidence);
      }
      if (replay.kind == EditReplayKind.applicable ||
          replay.kind == EditReplayKind.satisfied ||
          replay.kind == EditReplayKind.conflict) {
        proposal = replay.observation;
      } else {
        diagnostics.addAll(
          replay.diagnostics.isEmpty
              ? [
                  const EditorDiagnostic(
                    code: EditorDiagnosticCode.invalidValue,
                    message: "These changes cannot be applied to the current resource",
                  ),
                ]
              : replay.diagnostics,
        );
        retainedProposal = true;
      }
    }
    return EditGroupReview(
      saved: confirmed,
      original: selected.first.original,
      beforeGroup: before,
      proposal: retainedProposal ? selected.last.after : proposal,
      operations: selected.map((operation) => operation.id).toSet(),
      edits: selected.map((operation) => operation.edit).toList(),
      conflicts: conflicts,
      diagnostics: diagnostics,
    );
  }

  /// Replaces one reviewed unsent group atomically, retaining peer journal order.
  EditStageResult replaceUnsubmitted(
    EditGroupId id, {
    required Set<int> expectedOperations,
    required List<E> expectedEdits,
    E? replacement,
  }) {
    final owner = _groups[id];
    final selected = _operations
        .where((operation) => operation.group == id)
        .toList();
    if (_closed ||
        _saving != null ||
        !_state.available ||
        owner == null ||
        selected.isEmpty ||
        owner.frozen.isNotEmpty ||
        owner.phase.submitted) {
      return const EditStageResult.rejected(
        "Submitted or unavailable work cannot be replaced",
        null,
      );
    }
    if (!const SetEquality<int>().equals(
          selected.map((operation) => operation.id).toSet(),
          expectedOperations,
        ) ||
        !const DeepCollectionEquality().equals(
          selected.map((operation) => operation.edit).toList(),
          expectedEdits,
        )) {
      return const EditStageResult.rejected(
        "The local changes changed again",
        null,
      );
    }
    try {
      final candidate = <_EditOperation<S, E>>[];
      var working = confirmed;
      var inserted = false;
      for (final operation in _operations) {
        if (operation.group == id) {
          if (inserted) continue;
          inserted = true;
          if (replacement == null) continue;
          final replay = model.replay(working, replacement);
          if (replay.kind != EditReplayKind.applicable &&
              replay.kind != EditReplayKind.satisfied) {
            return EditStageResult.rejected(
              replay.diagnostics.firstOrNull?.message ??
                  "The reviewed proposal cannot be applied",
              replay.cause,
            );
          }
          final diagnostics = model.validateCommit(replay.observation);
          if (diagnostics.isNotEmpty) {
            return EditStageResult.rejected(diagnostics.first.message, null);
          }
          if (replay.kind == EditReplayKind.applicable) {
            candidate.add(
              _EditOperation(
                operation.id,
                id,
                replay.edit,
                working,
                replay.observation,
              ),
            );
          }
          working = replay.observation;
          continue;
        }
        final replay = model.replay(working, operation.edit);
        final copy = _EditOperation<S, E>.copy(operation);
        if (replay.kind == EditReplayKind.applicable ||
            replay.kind == EditReplayKind.satisfied ||
            replay.kind == EditReplayKind.conflict) {
          copy
            ..before = working
            ..after = replay.observation;
          working = replay.observation;
        }
        candidate.add(copy);
      }
      final dependencies = <EditGroupId, Set<EditGroupId>>{};
      final predecessors = <_EditOperation<S, E>>[];
      for (final operation in candidate) {
        dependencies
            .putIfAbsent(operation.group, () => {})
            .addAll(_dependencies(operation, predecessors));
        predecessors.add(operation);
      }
      bool cyclic(
        EditGroupId group,
        Set<EditGroupId> visiting,
        Set<EditGroupId> visited,
      ) {
        if (visiting.contains(group)) return true;
        if (!visited.add(group)) return false;
        visiting.add(group);
        for (final dependency in dependencies[group] ?? const <EditGroupId>{}) {
          if (cyclic(dependency, visiting, visited)) return true;
        }
        visiting.remove(group);
        return false;
      }

      if (dependencies.keys.any((group) => cyclic(group, {}, {}))) {
        return const EditStageResult.rejected(
          "This resolution would create a dependency cycle",
          null,
        );
      }
      final hold = holdStage();
      try {
        _tasks.remove(id)?.cancel();
        _requested.remove(id);
        for (final interaction
            in _interactions.values
                .where((value) => value.group == id)
                .toList()) {
          interaction.close();
        }
        _operations
          ..clear()
          ..addAll(candidate);
        owner
          ..phase = const EditGroupPhase.dirty()
          ..attempts = 0;
        _rebuild();
        if (replacement != null &&
            owner.policy == EditorCommitPolicy.autosaveChanges) {
          _schedule(id);
        }
      } finally {
        hold.release();
      }
      return EditStageResult.staged(id);
    } on Object catch (error) {
      return EditStageResult.rejected(
        "The reviewed changes could not be replaced",
        error,
      );
    }
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
  Object? submissionId(EditGroupId id) => _groups[id]?.lastSubmissionId;
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
        retireIdleGroups();
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
    this.lifetime,
  );
  final EditGroupLifetime lifetime;
  int controls = 0;
  Object? lastSubmissionId;
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
  _EditOperation.reowned(_EditOperation<S, E> other, this.group)
    : id = other.id,
      edit = other.edit,
      original = other.original,
      before = other.before,
      after = other.after;
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
    group
      ..submission = submission
      ..lastSubmissionId = submission.id;
    final result = await submission.run();
    if (!workspace._closed) await workspace._settle(group, result);
  }
}
