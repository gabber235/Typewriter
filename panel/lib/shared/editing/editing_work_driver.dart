import "package:typewriter_panel/typewriter_panel.dart";

/// Projects the common owner into activity and gives it a scoped lifetime.
final class EditingWorkDriver<S, E> extends ChangeNotifier
    implements WorkDriver, WorkReviewProvider {
  EditingWorkDriver({
    required this.id,
    required this.workspace,
    this.projectValues,
    this.onDispose,
    this.reviewFactory,
  }) {
    workspace.addListener(notifyListeners);
  }
  @override
  final WorkDriverId id;
  final EditingWorkspace<S, E> workspace;
  final Map<EditorResourceKey, LocalEditorValue> Function(EditingState<S>)?
  projectValues;
  final VoidCallback? onDispose;
  WorkReviewContent? Function(EditGroupId)? reviewFactory;
  @override
  WorkReviewContent? buildReview(WorkEntryId entry) =>
      reviewFactory?.call(_group(entry));
  @override
  WorkDriverSnapshot get snapshot => WorkDriverSnapshot(
    editorValues: projectValues?.call(workspace.state) ?? {},
    entries: [
      if (workspace.isPreparing)
        WorkEntryState(
          id: WorkEntryId(driver: id, identity: "preparation"),
          label: "Prepare changes",
          phase: "Preparing changes",
          retained: true,
          hasWork: true,
          blocksNavigation: true,
        ),
      for (final group in workspace.state.groups.values)
        WorkEntryState(
          id: WorkEntryId(driver: id, identity: group.id),
          label: group.label,
          phase: group.phase is EditGroupRejected
              ? "Save failed: ${group.phase.message}"
              : group.phase.message,
          details: _details(group),
          retained: true,
          hasWork: true,
          canReview: reviewFactory != null,
          canSave: workspace.canSave(group.id),
          canDiscard: workspace.canDiscard(group.id),
          canRetry: workspace.canRetry(group.id),
          blocksNavigation: true,
          saving: group.phase.active,
          needsAttention: group.phase.needsAttention,
        ),
    ],
  );
  List<WorkFact> _details(EditGroup<S> group) {
    final phase = group.phase;
    if (!phase.needsAttention) return const [];
    final diagnostics = switch (phase) {
      EditGroupRejected(cause: EditPreparationFailure(:final diagnostics)) =>
        diagnostics,
      _ => const <EditorDiagnostic>[],
    };
    if (diagnostics.isEmpty &&
        phase is! EditGroupRejected &&
        phase is! EditGroupRepeatedContention) {
      return const [];
    }
    return [
      WorkFact(
        label: "Phase",
        value: phase is EditGroupRejected
            ? "failed"
            : phase.runtimeType.toString(),
      ),
      if (phase is EditGroupRejected)
        WorkFact(label: "Reason", value: phase.message),
      for (final diagnostic in diagnostics) ...[
        WorkFact(label: "Code", value: diagnostic.code.name),
        WorkFact(
          label: "Diagnostic path",
          value: (diagnostic.path ?? editorRootPath).diagnosticLabel,
        ),
        for (final detail in diagnostic.details.entries)
          WorkFact(label: detail.key, value: detail.value),
      ],
      if (phase case EditGroupRepeatedContention(
        :final attempts,
        :final expected,
        :final observed,
      )) ...[
        const WorkFact(label: "Contention", value: "versionMismatch"),
        WorkFact(label: "Attempts", value: "$attempts total"),
        const WorkFact(label: "Retries", value: "3"),
        if (expected is int)
          WorkFact(label: "Expected version", value: "$expected"),
        if (observed is int)
          WorkFact(label: "Observed version", value: "$observed"),
      ],
    ];
  }

  EditGroupId _group(WorkEntryId entry) {
    if (entry.driver != id || entry.identity is! EditGroupId) {
      throw StateError("This entry belongs to another editing owner");
    }
    return entry.identity as EditGroupId;
  }

  @override
  Future<void> save(WorkEntryId entry) => workspace.save(_group(entry));
  @override
  bool discard(WorkEntryId entry) => workspace.discard(_group(entry));
  @override
  Future<void> retry(WorkEntryId entry) => workspace.retry(_group(entry));
  @override
  void dispose() {
    onDispose?.call();
    workspace
      ..removeListener(notifyListeners)
      ..dispose();
    super.dispose();
  }
}
