import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Typed authoring commands over the shared editing owner.
final class RealmEditing implements Listenable {
  RealmEditing({
    required RealmEditPersistence persistence,
    required LocalWorkCommands submissions,
    AuthoringDocument? initial,
    EditorDelayScheduler scheduler = const TimerEditorDelayScheduler(),
  }) : workspace = EditingWorkspace<AuthoringDocument, RealmPreparedEdit>(
         model: const RealmEditModel(),
         persistence: persistence,
         submissions: submissions,
         initial: initial,
         scheduler: scheduler,
       );
  RealmEditing.fromWorkspace(this.workspace);
  final EditingWorkspace<AuthoringDocument, RealmPreparedEdit> workspace;
  EditingState<AuthoringDocument> get state => workspace.state;
  AuthoringDocument get document => workspace.document;
  bool get hasPendingWork => workspace.hasPendingWork;
  bool get isPreparing => workspace.isPreparing;

  /// Captures both sides without awaiting, so an autosave cannot split the pair.
  OperationWorkspaceCapture captureOperationContext() {
    final confirmed = workspace.confirmed;
    final working = workspace.document;
    final observation = confirmed.confirmedObservation;
    if (observation == null || observation.value.isEmpty) {
      throw StateError("The saved authoring observation is unavailable");
    }
    if (working.generation != confirmed.generation) {
      throw StateError("The editor catalog changed");
    }
    return OperationWorkspaceCapture(
      document: working,
      revision: workspace.revision,
      context: skir.OperationWorkingContext(
        confirmedObservation: observation,
        overlay: skir.OperationWorkingOverlay(
          upserts: [
            for (final entry in working.entries.entries)
              if (confirmed.resource(entry.key) != entry.value.content)
                skir.OperationResourceUpsert(
                  resource: entry.key,
                  content: entry.value.content,
                ),
          ],
          removals: [
            for (final id in confirmed.entries.keys)
              if (!working.entries.containsKey(id)) id,
          ],
        ),
      ),
    );
  }

  RealmEditingBinding attach(
    skir.ResourceId resource, {
    EditorCommitPolicy policy = EditorCommitPolicy.autosaveChanges,
  }) => RealmEditingBinding(
    this,
    resource,
    workspace.createGroup(
      label: "Edit ${resource.value}",
      key: resource,
      policy: policy,
    ),
  );
  EditStageResult edit({
    required String label,
    required void Function(AuthoringEdit edit) apply,
    EditorCommitPolicy policy = EditorCommitPolicy.autosaveChanges,
    EditGroupId? group,
    AuthoringDocument? from,
  }) {
    final id = group ?? workspace.createGroup(label: label, policy: policy);
    if (!workspace.canEdit(id)) {
      return const EditStageResult.rejected("Authoring is not ready", null);
    }
    try {
      final branch = AuthoringEdit.fromDocument(from ?? document);
      apply(branch);
      branch.requireValid();
      return workspace.stage(id, branch.capture(), label: label);
    } on Object catch (error) {
      return EditStageResult.rejected(error.toString(), error);
    }
  }

  Future<EditStageResult> prepare({
    required String label,
    required Future<void> Function(AuthoringEdit edit) apply,
    EditorCommitPolicy policy = EditorCommitPolicy.autosaveChanges,
    EditGroupId? group,
    AuthoringDocument? from,
  }) => workspace.prepare(
    group ?? workspace.createGroup(label: label, policy: policy),
    (observation) async {
      final branch = AuthoringEdit.fromDocument(observation);
      await apply(branch);
      branch.requireValid();
      return branch.capture();
    },
    from: from,
    label: label,
  );
  EditStageResult stagePrepared({
    required EditGroupId group,
    required String label,
    required skir.PreparedEdit edit,
  }) => this.edit(
    group: group,
    label: label,
    apply: (branch) => branch.applyPrepared(edit),
  );

  /// Refreshes saved facts before capturing a synchronous journal review.
  Future<AuthoringConflictReview> reviewConflict(EditGroupId id) async {
    workspace.inspectUnsubmitted(id);
    if (workspace.applying) {
      throw const EditPreparationFailure("Wait for the current save to finish");
    }
    final observation = await workspace.persistence.refresh();
    if (workspace.applying) {
      throw const EditPreparationFailure("Wait for the current save to finish");
    }
    workspace.acceptConfirmed(observation);
    return const RealmEditModel().review(id, workspace.inspectUnsubmitted(id));
  }

  EditStageResult resolveConflict(
    AuthoringConflictReview reviewed,
    AuthoringConflictChoice choice,
  ) {
    try {
      if (workspace.applying) {
        return const EditStageResult.rejected(
          "Wait for the current save to finish",
          null,
        );
      }
      final current = workspace.inspectUnsubmitted(reviewed.group);
      if (!reviewed.matches(current)) {
        return const EditStageResult.rejected(
          "These changes changed again. Review the current values",
          null,
        );
      }
      final replacement = switch (choice) {
        AuthoringConflictChoice.useSaved => null,
        AuthoringConflictChoice.keepMine =>
          const RealmEditModel().resolveReviewed(reviewed, current.beforeGroup),
      };
      return workspace.replaceUnsubmitted(
        reviewed.group,
        expectedOperations: reviewed.operations,
        expectedEdits: reviewed.edits,
        replacement: replacement,
      );
    } on Object catch (error) {
      return EditStageResult.rejected(
        error is EditPreparationFailure
            ? error.message
            : "These changes cannot be applied to the current saved values",
        error,
      );
    }
  }

  void acceptConfirmed(AuthoringDocument observation) =>
      workspace.acceptConfirmed(observation);
  void acceptFailure(Object error) => workspace.acceptFailure(error);
  Future<void> save(EditGroupId id) => workspace.save(id);
  Future<void> retry(EditGroupId id) => workspace.retry(id);
  bool discard(EditGroupId id) => workspace.discard(id);
  bool disposeEmptyGroup(EditGroupId id) => workspace.disposeEmptyGroup(id);
  bool canSave(EditGroupId id) => workspace.canSave(id);
  bool canRetry(EditGroupId id) => workspace.canRetry(id);
  bool canDiscard(EditGroupId id) => workspace.canDiscard(id);
  bool hasWorkFor(skir.ResourceId resource) => workspace.hasWorkFor(resource);
  Future<void> refreshConfirmed() => workspace.refreshConfirmed();
  @override
  void addListener(VoidCallback listener) => workspace.addListener(listener);
  @override
  void removeListener(VoidCallback listener) =>
      workspace.removeListener(listener);
  void dispose() => workspace.dispose();
}
