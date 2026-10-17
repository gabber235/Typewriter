import "package:typewriter_panel/typewriter_panel.dart";

part "edit_control.freezed.dart";

/// Actions for the work reached through a presentation binding.
abstract interface class EditControl implements Listenable {
  EditControlState get state;
  Future<void> apply();
  bool discard();
  Future<void> retry();
  Future<void> refresh();
  void dispose();
}

@freezed
abstract class EditControlState with _$EditControlState {
  const factory EditControlState({
    @Default(false) bool hasWork,
    @Default(false) bool showControls,
    @Default(false) bool canApply,
    @Default(false) bool canDiscard,
    @Default(false) bool canRetry,
    @Default(false) bool hasSubmittedWork,
    @Default(false) bool hasLaterEdits,
    String? status,
    @Default([]) List<EditorDiagnostic> diagnostics,
  }) = _EditControlState;
}

/// One policy for presenting manual save and recovery controls.
extension EditGroupControls<S> on EditGroup<S> {
  bool get showControls =>
      policy == EditorCommitPolicy.applyResource || phase.needsAttention;
}

/// A disposable view of one group. It owns no draft or persistence state.
final class EditGroupControl<S, E> extends ChangeNotifier
    implements EditControl, EditApplyControl {
  EditGroupControl(this.workspace, this.id) {
    workspace.addListener(_changed);
  }
  final EditingWorkspace<S, E> workspace;
  final EditGroupId id;
  @override
  Iterable<EditApplyRequest> get applyRequests => [workspace.applyRequest(id)];
  bool _closed = false;
  bool get canEdit => !_closed && workspace.canEdit(id);
  @override
  EditControlState get state {
    final group = workspace.state.groups[id];
    final diagnostics = workspace.state.working == null
        ? <EditorDiagnostic>[]
        : workspace.model.validateCommit(workspace.document);
    return EditControlState(
      hasWork: group != null,
      showControls: group?.showControls ?? false,
      canApply: !_closed && workspace.canSave(id) && diagnostics.isEmpty,
      canDiscard: !_closed && workspace.canDiscard(id),
      canRetry: !_closed && workspace.canRetry(id),
      hasSubmittedWork: workspace.hasSubmittedWork(id),
      hasLaterEdits: workspace.hasLaterEdits(id),
      status: group?.phase is EditGroupDirty<S> ? null : group?.phase.message,
      diagnostics: diagnostics,
    );
  }

  @override
  Future<void> apply() => _closed ? Future.value() : workspace.save(id);
  @override
  bool discard() => !_closed && workspace.discard(id);
  @override
  Future<void> retry() => _closed ? Future.value() : workspace.retry(id);
  @override
  Future<void> refresh() =>
      _closed ? Future.value() : workspace.refreshConfirmed();
  void _changed() {
    if (!_closed) notifyListeners();
  }

  @override
  void dispose() {
    if (_closed) return;
    _closed = true;
    workspace.removeListener(_changed);
    super.dispose();
  }
}

/// Value projections expose controls through this capability without a feature cast.
abstract interface class EditingControlOwner {
  EditControl bindControl();
}

/// Combines group actions while preserving each independent request outcome.
final class EditSelectionControl extends ChangeNotifier
    implements EditControl, EditApplyControl {
  EditSelectionControl(Iterable<EditControl> controls)
    : controls = List.unmodifiable(controls) {
    for (final control in this.controls) {
      control.addListener(notifyListeners);
    }
  }
  final List<EditControl> controls;
  @override
  Iterable<EditApplyRequest> get applyRequests => [
    for (final control in controls)
      if (control case final EditApplyControl applying)
        ...applying.applyRequests,
  ];
  @override
  EditControlState get state {
    final pending = controls
        .map((control) => control.state)
        .where((state) => state.hasWork)
        .toList();
    return EditControlState(
      hasWork: pending.isNotEmpty,
      showControls: pending.any((state) => state.showControls),
      canApply: pending.isNotEmpty && pending.every((state) => state.canApply),
      canDiscard:
          pending.isNotEmpty && pending.every((state) => state.canDiscard),
      canRetry: pending.any((state) => state.canRetry),
      hasSubmittedWork: pending.any((state) => state.hasSubmittedWork),
      hasLaterEdits: pending.any((state) => state.hasLaterEdits),
      status: pending.firstWhereOrNull((state) => state.status != null)?.status,
      diagnostics: [for (final state in pending) ...state.diagnostics],
    );
  }

  @override
  Future<void> apply() async {
    if (!state.canApply) return;
    await const EditApplyCoordinator().apply(applyRequests);
  }

  @override
  bool discard() {
    if (!state.canDiscard) return false;
    var changed = false;
    for (final control in controls) {
      changed = control.discard() || changed;
    }
    return changed;
  }

  @override
  Future<void> retry() async {
    await Future.wait([
      for (final control in controls)
        if (control.state.canRetry) control.retry(),
    ]);
  }

  @override
  Future<void> refresh() async {
    await Future.wait(controls.map((control) => control.refresh()));
  }

  @override
  void dispose() {
    for (final control in controls) {
      control
        ..removeListener(notifyListeners)
        ..dispose();
    }
    super.dispose();
  }
}

/// Exposes preparation into real request boundaries without exposing domain types.
abstract interface class EditApplyControl {
  Iterable<EditApplyRequest> get applyRequests;
}
