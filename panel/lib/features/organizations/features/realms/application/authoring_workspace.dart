import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "authoring_workspace.freezed.dart";
part "authoring_workspace.g.dart";
part "authoring_document.dart";
part "authoring_edit.dart";
part "authoring_binding.dart";

/// External settlement for shared work. Only the production adapter sends edits.
abstract interface class AuthoringWorkspaceTransport {
  Future<skir.CommitPreparedEditResponse> commit(skir.PreparedEdit edit);
  Future<AuthoringDocument> fetchConfirmed();
}

/// Owns shared working values, operation groups, and a single submission lane.
///
/// Bindings share form groups. Independent commands create separate groups even
/// when they touch the same resource. Only observed facts create dependencies.
final class AuthoringWorkspace extends ChangeNotifier {
  AuthoringWorkspace({
    required this.transport,
    AuthoringDocument? initial,
    this.scheduler = const TimerEditorDelayScheduler(),
  }) {
    if (initial != null) acceptConfirmed(initial);
  }

  static const debounce = Duration(milliseconds: 250);
  final AuthoringWorkspaceTransport transport;
  final EditorDelayScheduler scheduler;
  AuthoringWorkspaceState _state = const AuthoringWorkspaceState();
  AuthoringWorkspaceState get state => _state;
  AuthoringDocument get document =>
      _state.working ?? (throw StateError("Authoring is not ready"));
  final _groups = <AuthoringGroupId, _WorkingGroup>{};
  final _forms = <skir.ResourceId, AuthoringGroupId>{};
  final _operations = <_AuthoringOperation>[];
  final _tasks = <AuthoringGroupId, EditorScheduledTask>{};
  final _requested = <AuthoringGroupId>{};
  var _identity = 0;
  var _revision = 0;
  var _closed = false;
  var _preparations = 0;
  bool get hasPendingWork => _preparations != 0 || _operations.isNotEmpty;
  Future<void>? _saving;
  AuthoringDocument? _deferredConfirmed;

  AuthoringBinding attach(
    skir.ResourceId resource, {
    EditorCommitPolicy policy = EditorCommitPolicy.autosaveChanges,
  }) {
    if (_closed) throw StateError("The authoring workspace is closed");
    final id = _forms.putIfAbsent(
      resource,
      () => AuthoringGroupId(++_identity),
    );
    final group = _groups.putIfAbsent(
      id,
      () => _WorkingGroup(id, policy, "Edit resource"),
    );
    if (group.policy != policy) {
      throw StateError("Forms for one resource require the same save policy");
    }
    return AuthoringBinding._(this, resource, id);
  }

  AuthoringEditResult edit({
    required String label,
    required void Function(AuthoringEdit edit) apply,
    EditorCommitPolicy policy = EditorCommitPolicy.autosaveChanges,
    AuthoringGroupId? group,
    AuthoringDocument? from,
  }) {
    if (_closed ||
        _state.working == null ||
        _state.confirmed?.generation != _state.working?.generation) {
      return const AuthoringEditResult.rejected("Authoring is not ready", null);
    }
    final id = group ?? AuthoringGroupId(++_identity);
    final owner = _groups.putIfAbsent(
      id,
      () => _WorkingGroup(id, policy, label),
    );
    if (owner.phase.blocked) {
      return AuthoringEditResult.rejected(owner.phase.message, null);
    }
    final branch = AuthoringEdit.fromDocument(from ?? document);
    try {
      apply(branch);
      return _stage(id, label, branch);
    } on Object catch (error) {
      return AuthoringEditResult.rejected(error.toString(), error);
    } finally {
      _removeUnusedCommand(id);
    }
  }

  Future<AuthoringEditResult> prepare({
    required String label,
    required Future<void> Function(AuthoringEdit edit) apply,
    EditorCommitPolicy policy = EditorCommitPolicy.autosaveChanges,
    AuthoringGroupId? group,
    AuthoringDocument? from,
  }) async {
    if (_closed ||
        _state.working == null ||
        _state.confirmed?.generation != _state.working?.generation) {
      return const AuthoringEditResult.rejected("Authoring is not ready", null);
    }
    final id = group ?? AuthoringGroupId(++_identity);
    final owner = _groups.putIfAbsent(
      id,
      () => _WorkingGroup(id, policy, label),
    );
    if (owner.phase.blocked) {
      return AuthoringEditResult.rejected(owner.phase.message, null);
    }
    final branch = AuthoringEdit.fromDocument(from ?? document);
    _preparations++;
    notifyListeners();
    try {
      await apply(branch);
      if (_closed || owner.phase.blocked) {
        return const AuthoringEditResult.rejected(
          "The authoring operation is unavailable",
          null,
        );
      }
      return _stage(id, label, branch);
    } on Object catch (error) {
      return AuthoringEditResult.rejected(error.toString(), error);
    } finally {
      _preparations--;
      _removeUnusedCommand(id);
      if (!_closed) notifyListeners();
    }
  }

  AuthoringEditResult _stage(
    AuthoringGroupId id,
    String label,
    AuthoringEdit branch,
  ) {
    if (_closed) {
      return const AuthoringEditResult.rejected(
        "The authoring workspace closed",
        null,
      );
    }
    if (branch.generation != document.generation ||
        branch.generation != _state.confirmed?.generation) {
      return const AuthoringEditResult.rejected(
        "The editor catalog changed",
        null,
      );
    }
    branch.requireValid();
    if (branch.intents.isEmpty) return const AuthoringEditResult.unchanged();
    final current = AuthoringEdit.fromDocument(document);
    for (final expected in branch.expectations) {
      if (!_sameExpectation(expected, current._actual(expected))) {
        return const AuthoringEditResult.rejected(
          "Values changed while the operation was prepared",
          null,
        );
      }
    }
    final operation = _AuthoringOperation(
      ++_identity,
      id,
      label,
      branch.prepare(),
      document,
      branch.toDocument(revision: ++_revision),
      branch.initializationFindings
          .skip(branch._inheritedFindings)
          .toList(growable: false),
    );
    final dependencies = _dependencies(operation, _operations);
    if (dependencies.any((other) => _dependsOn(other, id, {}))) {
      return const AuthoringEditResult.rejected(
        "Apply or discard related work before combining these changes",
        null,
      );
    }
    _operations.add(operation);
    _groups[id]!.label = label;
    _rebuild();
    if (_groups[id]!.policy == EditorCommitPolicy.autosaveChanges) {
      _schedule(id);
    }
    return AuthoringEditResult.staged(id);
  }

  bool _dependsOn(
    AuthoringGroupId current,
    AuthoringGroupId target,
    Set<AuthoringGroupId> visited,
  ) {
    if (current == target) return true;
    if (!visited.add(current)) return false;
    return _groupDependencies(current)
        .any((other) => _dependsOn(other, target, visited));
  }

  Set<AuthoringGroupId> _dependencies(
    _AuthoringOperation operation,
    Iterable<_AuthoringOperation> predecessors,
  ) {
    final result = <AuthoringGroupId>{};
    final confirmed = _state.confirmed;
    if (confirmed == null) return result;
    final baseline = AuthoringEdit.fromDocument(confirmed);
    final previousOperations = predecessors.toList(growable: false);
    for (final fact in operation.edit.expectations) {
      if (_sameExpectation(fact, baseline._actual(fact))) continue;
      for (final previous in previousOperations.reversed) {
        final before = AuthoringEdit.fromDocument(previous.before);
        final after = AuthoringEdit.fromDocument(previous.after);
        if (_sameExpectation(before._actual(fact), after._actual(fact))) {
          continue;
        }
        if (previous.group != operation.group) result.add(previous.group);
        break;
      }
    }
    return result;
  }

  Set<AuthoringGroupId> _groupDependencies(AuthoringGroupId group) {
    final result = <AuthoringGroupId>{};
    final previous = <_AuthoringOperation>[];
    for (final operation in _operations) {
      if (operation.group == group) {
        result.addAll(_dependencies(operation, previous));
      }
      previous.add(operation);
    }
    return result;
  }

  void acceptConfirmed(AuthoringDocument confirmed) {
    if (_closed) return;
    if (_saving != null) {
      _deferredConfirmed = confirmed;
      return;
    }
    _state = _state.copyWith(confirmed: confirmed, failure: null);
    _rebuild();
    final ready = _requested.firstWhereOrNull(
      (id) => _groups[id]?.phase is AuthoringGroupDirty,
    );
    if (ready != null) unawaited(save(ready));
  }

  void acceptFailure(Object error) {
    if (_closed) return;
    _state = _state.copyWith(failure: error);
    notifyListeners();
  }

  void _rebuild() {
    final confirmed = _state.confirmed;
    if (confirmed == null || _closed) return;
    if (_operations.any(
      (operation) => operation.edit.catalog != confirmed.generation,
    )) {
      for (final group in _groups.values) {
        if (group.frozen.isEmpty &&
            _operations.any((operation) => operation.group == group.id)) {
          group.phase = const AuthoringGroupPhase.catalogChanged();
        }
      }
      _publish(_state.working ?? confirmed);
      return;
    }
    var branch = AuthoringEdit.fromDocument(confirmed);
    for (final operation in _operations) {
      final group = _groups[operation.group]!;
      for (final expected in operation.edit.expectations) {
        final actual = branch._actual(expected, original: false);
        if (!_sameExpectation(expected, actual) && !group.phase.blocked) {
          group.phase = AuthoringGroupPhase.conflict(
            "The Realm changed before this edit was saved",
            expected,
            actual,
          );
        }
      }
      try {
        final candidate = branch.fork();
        for (final intent in operation.edit.intents) {
          final failure = candidate._replay(intent);
          if (failure != null) throw StateError(failure);
        }
        candidate.requireValid();
        candidate._initializationFindings.addAll(operation.findings);
        operation
          ..before = branch.toDocument()
          ..after = candidate.toDocument();
        branch = candidate;
      } on Object catch (error) {
        if (group.frozen.isNotEmpty) continue;
        final missing = operation.before.entries.keys.firstWhereOrNull(
          (resource) =>
              !branch.resources.containsKey(resource) &&
              operation.edit.expectations.any(
                (fact) =>
                    fact is skir.EditExpectation_resourceExistsWrapper &&
                    fact.value.id == resource &&
                    fact.value.expected,
              ),
        );
        group.phase = missing == null
            ? AuthoringGroupPhase.rejected(error.toString(), error)
            : AuthoringGroupPhase.resourceMissing(missing, operation.after);
      }
    }
    for (final group in _groups.values) {
      if (!group.phase.blocked && group.phase is! AuthoringGroupSaving) {
        final dependencies = _groupDependencies(group.id);
        group.phase = dependencies.isEmpty
            ? const AuthoringGroupPhase.dirty()
            : AuthoringGroupPhase.awaitingDependency(dependencies);
      }
    }
    _publish(branch.toDocument(revision: ++_revision));
  }

  void _removeUnusedCommand(AuthoringGroupId id) {
    if (_preparations != 0 ||
        _forms.containsValue(id) ||
        _operations.any((operation) => operation.group == id)) {
      return;
    }
    _groups.remove(id);
    _requested.remove(id);
    _tasks.remove(id)?.cancel();
  }

  void _publish(AuthoringDocument working) {
    for (final id in _groups.keys.toList()) {
      _removeUnusedCommand(id);
    }
    final snapshots = <AuthoringGroupId, AuthoringGroup>{};
    for (final group in _groups.values) {
      final operations = _operations
          .where((operation) => operation.group == group.id)
          .toList();
      if (operations.isEmpty) continue;
      snapshots[group.id] = AuthoringGroup(
        id: group.id,
        label: group.label,
        policy: group.policy,
        phase: group.phase,
        operationCount: operations.length,
        original: operations.first.original,
        resources: Set.unmodifiable({
          for (final op in operations) ...op.resources,
        }),
      );
    }
    _state = _state.copyWith(
      working: working,
      groups: Map.unmodifiable(snapshots),
    );
    notifyListeners();
  }

  void _schedule(AuthoringGroupId id) {
    _tasks.remove(id)?.cancel();
    final task = scheduler.schedule(debounce);
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

  Future<void> save(AuthoringGroupId id) {
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
    // Yield once so the lane is installed before a synchronous fixture replies.
    await Future<void>.value();
    while (!_closed) {
      final id = _requested.firstWhereOrNull(
        (id) =>
            _operations.any((operation) => operation.group == id) &&
            _groups[id]!.phase is AuthoringGroupDirty,
      );
      if (id == null) break;
      _requested.remove(id);
      await _submit(_groups[id]!);
    }
  }

  Future<void> _submit(_WorkingGroup group) async {
    final frozen = _operations
        .where((operation) => operation.group == group.id)
        .toList();
    final branch = AuthoringEdit.fromDocument(_state.confirmed!);
    try {
      for (final operation in frozen) {
        for (final expected in operation.edit.expectations) {
          final actual = branch._actual(expected, original: false);
          if (!_sameExpectation(expected, actual)) {
            group.phase = AuthoringGroupPhase.conflict(
              "The values needed by this save changed",
              expected,
              actual,
            );
            _rebuild();
            return;
          }
        }
        for (final intent in operation.edit.intents) {
          final failure = branch._replay(intent);
          if (failure != null) throw StateError(failure);
        }
      }
      branch.requireValid();
      group
        ..frozen = frozen.map((operation) => operation.id).toSet()
        ..phase = const AuthoringGroupPhase.saving();
      _rebuild();
      final response = await transport.commit(branch.prepare());
      if (_closed) return;
      switch (response) {
        case skir.CommitPreparedEditResponse_resultWrapper(
          value: skir.CommitResult.committed,
        ):
          group.phase = const AuthoringGroupPhase.committedAwaitingRefresh(
            null,
          );
          _rebuild();
          try {
            final confirmed = await transport.fetchConfirmed();
            if (_closed) return;
            _finishCommitted(group, confirmed);
          } on Object catch (error) {
            if (_closed) return;
            group.phase = AuthoringGroupPhase.committedAwaitingRefresh(error);
          }
        case skir.CommitPreparedEditResponse_resultWrapper(
          value: skir.CommitResult_conflictWrapper(:final value),
        ):
          group
            ..frozen = {}
            ..phase = AuthoringGroupPhase.conflict(
              response.rejectionMessage,
              value.firstOrNull?.expected,
              value.firstOrNull?.actual,
            );
        case skir.CommitPreparedEditResponse_resultWrapper(
          value: skir.CommitResult_catalogChangedWrapper(),
        ):
          group
            ..frozen = {}
            ..phase = const AuthoringGroupPhase.catalogChanged();
        case skir.CommitPreparedEditResponse_resultWrapper(
          value: skir.CommitResult_rejectedWrapper(),
        ):
          group
            ..frozen = {}
            ..phase = AuthoringGroupPhase.rejected(
              response.rejectionMessage,
              response,
            );
        case skir.CommitPreparedEditResponse_internalErrorWrapper() ||
            skir.CommitPreparedEditResponse_unknown():
          group.phase = AuthoringGroupPhase.uncertain(response);
        default:
          group.phase = AuthoringGroupPhase.uncertain(response);
      }
    } on Object catch (error) {
      if (_closed) return;
      if (group.frozen.isEmpty ||
          error is SubmissionException &&
              error.submission.result is SubmissionNotSubmitted) {
        group
          ..frozen = {}
          ..phase = AuthoringGroupPhase.rejected(
            "The edit was not submitted",
            error,
          );
      } else {
        group.phase = AuthoringGroupPhase.uncertain(error);
      }
    }
    if (_closed) return;
    _rebuild();
    if (_operations.any((operation) => operation.group == group.id) &&
        group.phase is AuthoringGroupDirty &&
        group.policy == EditorCommitPolicy.autosaveChanges) {
      _schedule(group.id);
    }
  }

  void _finishCommitted(_WorkingGroup group, AuthoringDocument confirmed) {
    _operations.removeWhere((operation) => group.frozen.contains(operation.id));
    group
      ..frozen = {}
      ..phase = const AuthoringGroupPhase.dirty();
    _deferredConfirmed = null;
    _state = _state.copyWith(confirmed: confirmed, failure: null);
    _rebuild();
  }

  /// Refreshes known saved batches without resubmitting uncertain operations.
  Future<void> refreshConfirmed() async {
    if (_saving != null) return;
    late final AuthoringDocument confirmed;
    try {
      confirmed = await transport.fetchConfirmed();
    } on Object catch (error) {
      acceptFailure(error);
      return;
    }
    if (_closed) return;
    for (final group in _groups.values) {
      if (group.phase is AuthoringGroupCommittedAwaitingRefresh) {
        _operations.removeWhere(
          (operation) => group.frozen.contains(operation.id),
        );
        group
          ..frozen = {}
          ..phase = const AuthoringGroupPhase.dirty();
      }
    }
    acceptConfirmed(confirmed);
    for (final group in _groups.values) {
      if (group.phase is AuthoringGroupDirty &&
          group.policy == EditorCommitPolicy.autosaveChanges &&
          _operations.any((operation) => operation.group == group.id)) {
        _schedule(group.id);
      }
    }
  }

  bool canDiscard(AuthoringGroupId id) {
    final group = _groups[id];
    return group != null &&
        _operations.any(
          (operation) =>
              operation.group == id && !group.frozen.contains(operation.id),
        );
  }

  bool discard(AuthoringGroupId id) {
    final group = _groups[id];
    if (group == null || !canDiscard(id)) return false;
    _tasks.remove(id)?.cancel();
    _requested.remove(id);
    _operations.removeWhere(
      (operation) =>
          operation.group == id && !group.frozen.contains(operation.id),
    );
    if (group.frozen.isEmpty) {
      group.phase = const AuthoringGroupPhase.dirty();
    }
    _rebuild();
    for (final other in _requested.toList()) {
      if (_groups[other]?.phase is AuthoringGroupDirty) unawaited(save(other));
    }
    return true;
  }

  bool hasWorkFor(skir.ResourceId resource) =>
      state.groups.values.any((group) => group.resources.contains(resource));

  @override
  void dispose() {
    _closed = true;
    for (final task in _tasks.values) {
      task.cancel();
    }
    _tasks.clear();
    super.dispose();
  }
}

final class _WorkingGroup {
  _WorkingGroup(this.id, this.policy, this.label);
  final AuthoringGroupId id;
  final EditorCommitPolicy policy;
  String label;
  AuthoringGroupPhase phase = const AuthoringGroupPhase.dirty();
  Set<int> frozen = {};
}

final class _AuthoringOperation {
  _AuthoringOperation(
    this.id,
    this.group,
    this.label,
    this.edit,
    this.before,
    this.after,
    this.findings,
  ) : original = before;
  final int id;
  final AuthoringGroupId group;
  final String label;
  final skir.PreparedEdit edit;
  final AuthoringDocument original;
  AuthoringDocument before;
  AuthoringDocument after;
  final List<skir.InitializationDiagnostic> findings;
  Set<skir.ResourceId> get resources => {
    for (final id in {...before.entries.keys, ...after.entries.keys})
      if (before.entry(id) != after.entry(id)) id,
  };
}

@riverpod
AsyncValue<AuthoringDocument> confirmedAuthoringDocument(
  Ref ref,
  AuthoringScope scope,
) {
  final state = ref.watch(
    authoringSessionProvider(scope.organizationId, scope.realmId),
  );
  final document = state.confirmedDocument;
  if (document != null) return AsyncData(document);
  if (state.failure case final error?) {
    return AsyncError(error, StackTrace.current);
  }
  return const AsyncLoading();
}

@riverpod
AuthoringWorkspaceTransport authoringWorkspaceTransport(
  Ref ref,
  AuthoringScope scope,
) => _SessionWorkspaceTransport(ref, scope);

final class _SessionWorkspaceTransport implements AuthoringWorkspaceTransport {
  _SessionWorkspaceTransport(this.ref, this.scope);
  final Ref ref;
  final AuthoringScope scope;
  AuthoringSession get session => ref.read(
    authoringSessionProvider(scope.organizationId, scope.realmId).notifier,
  );
  @override
  Future<skir.CommitPreparedEditResponse> commit(skir.PreparedEdit edit) => ref
      .read(localWorkControllerProvider)
      .execute(session.prepareCommit(edit));
  @override
  Future<AuthoringDocument> fetchConfirmed() async {
    await session.refresh();
    return ref
            .read(authoringSessionProvider(scope.organizationId, scope.realmId))
            .confirmedDocument ??
        (throw StateError("Current Realm values are unavailable"));
  }
}

@riverpod
AuthoringWorkspace authoringWorkspace(Ref ref, AuthoringScope scope) {
  ref.watch(localWorkScopeProvider);
  final workspace = AuthoringWorkspace(
    transport: ref.watch(authoringWorkspaceTransportProvider(scope)),
  );
  ref.listen(confirmedAuthoringDocumentProvider(scope), (_, next) {
    if (next.value case final document?) {
      workspace.acceptConfirmed(document);
    } else if (next.error case final error?) {
      workspace.acceptFailure(error);
    }
  }, fireImmediately: true);
  KeepAliveLink? pending;
  void updated() {
    if (workspace.hasPendingWork) {
      pending ??= ref.keepAlive();
    } else {
      pending?.close();
      pending = null;
    }
  }

  workspace.addListener(updated);
  ref.onDispose(() {
    workspace
      ..removeListener(updated)
      ..dispose();
  });
  return workspace;
}

@riverpod
AuthoringWorkspaceState authoringWorkspaceState(Ref ref, AuthoringScope scope) {
  final workspace = ref.watch(authoringWorkspaceProvider(scope))
    ..addListener(ref.invalidateSelf);
  ref.onDispose(() => workspace.removeListener(ref.invalidateSelf));
  return workspace.state;
}

@riverpod
AsyncValue<AuthoringDocument> workingAuthoringDocument(
  Ref ref,
  AuthoringScope scope,
) {
  final state = ref.watch(authoringWorkspaceStateProvider(scope));
  if (state.working case final document?) return AsyncData(document);
  if (state.failure case final error?) {
    return AsyncError(error, StackTrace.current);
  }
  return const AsyncLoading();
}

@riverpod
AuthoringScope? selectedAuthoringScope(Ref ref) {
  final organization = ref.watch(organizationIdProvider);
  final realm = ref.watch(realmIdProvider);
  return organization == null || realm == null
      ? null
      : AuthoringScope(organizationId: organization, realmId: realm);
}

@riverpod
AsyncValue<AuthoringDocument> selectedWorkingAuthoringDocument(Ref ref) {
  final scope = ref.watch(selectedAuthoringScopeProvider);
  return scope == null
      ? const AsyncLoading()
      : ref.watch(workingAuthoringDocumentProvider(scope));
}

extension AuthoringWorkspaceRef on Ref {
  AuthoringWorkspace readAuthoringWorkspace() {
    final scope = read(selectedAuthoringScopeProvider);
    if (scope == null) throw StateError("No Realm selected");
    return read(authoringWorkspaceProvider(scope));
  }
}

extension AuthoringWorkspaceWidgetRef on WidgetRef {
  AuthoringWorkspace readAuthoringWorkspace() {
    final scope = read(selectedAuthoringScopeProvider);
    if (scope == null) throw StateError("No Realm selected");
    return read(authoringWorkspaceProvider(scope));
  }
}
