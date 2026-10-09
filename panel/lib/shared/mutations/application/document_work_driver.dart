import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Adapts a document editor to scoped work while retaining its reconciliation owner.
final class DocumentWorkDriver extends ChangeNotifier implements WorkDriver {
  DocumentWorkDriver(this.key, this.resource) {
    resource.listener = notifyListeners;
    resource.source.addListener(notifyListeners);
  }

  final EditorResourceKey key;
  final EditorResource resource;
  @override
  WorkDriverId get id => WorkDriverId(domain: "document", scope: key);
  WorkEntryId get entry => WorkEntryId(driver: id, identity: key);

  @override
  WorkDriverSnapshot get snapshot {
    final source = resource.source;
    final save = source.saveState(skir.ValuePath(segments: []));
    final diagnostics = save.diagnostics.isNotEmpty
        ? save.diagnostics
        : source.draftDiagnostics;
    final uncertain = save.phase == EditorSavePhase.uncertain;
    final saving = save.phase == EditorSavePhase.saving;
    return WorkDriverSnapshot(
      entries: [
        WorkEntryState(
          id: entry,
          label: resource.label,
          phase: switch (save.phase) {
            EditorSavePhase.failed =>
              diagnostics.isEmpty
                  ? "Save failed"
                  : "Save failed: ${diagnostics.first.message}",
            EditorSavePhase.conflict =>
              "Changed elsewhere. Resolve the conflict before saving.",
            EditorSavePhase.repeatedContention =>
              "Changed repeatedly elsewhere. Retry when other edits stop.",
            EditorSavePhase.uncertain =>
              "Outcome unknown. Verify before retrying.",
            EditorSavePhase.deletedElsewhere => "Deleted elsewhere.",
            EditorSavePhase.saving => "Saving",
            _ =>
              source.commitPolicy == EditorCommitPolicy.applyResource
                  ? "Configuration draft"
                  : "Unsaved changes",
          },
          details: [
            WorkFact(label: "Phase", value: save.phase.name),
            if (save.path != null)
              WorkFact(label: "Path", value: save.path!.diagnosticLabel),
            if (save.submissionId?.toString()._canonicalSubmissionId
                case final submission?)
              WorkFact(label: "Submission", value: submission),
            if (save.contention case final contention?) ...[
              WorkFact(label: "Contention", value: contention.kind.name),
              WorkFact(
                label: "Attempts",
                value: "${contention.attempts} total",
              ),
              WorkFact(label: "Retries", value: "${contention.retryLimit}"),
              if (contention.expectedVersion != null)
                WorkFact(
                  label: "Expected version",
                  value: contention.expectedVersion.toString(),
                ),
              if (contention.observedVersion != null)
                WorkFact(
                  label: "Observed version",
                  value: contention.observedVersion.toString(),
                ),
              WorkFact(
                label: "Contention paths",
                value: contention.paths
                    .map((path) => path.diagnosticLabel)
                    .join(", "),
              ),
            ],
            for (final diagnostic in diagnostics) ...[
              WorkFact(label: "Reason", value: diagnostic.message),
              WorkFact(label: "Code", value: diagnostic.code.name),
              if (diagnostic.path != null)
                WorkFact(
                  label: "Diagnostic path",
                  value: diagnostic.path!.diagnosticLabel,
                ),
            ],
          ],
          hasWork: source.hasWork,
          retained: source.hasWork,
          canSave:
              source.hasWork &&
              !source.readOnly &&
              {
                EditorSavePhase.pending,
                EditorSavePhase.idle,
              }.contains(save.phase) &&
              diagnostics.isEmpty,
          canDiscard:
              source.hasWork && !source.readOnly && !saving && !uncertain,
          canRetry: save.canRetry && !source.readOnly,
          blocksNavigation: source.hasWork,
          saving: saving,
          needsAttention: {
            EditorSavePhase.failed,
            EditorSavePhase.conflict,
            EditorSavePhase.uncertain,
            EditorSavePhase.repeatedContention,
            EditorSavePhase.deletedElsewhere,
          }.contains(save.phase),
          needsInput: diagnostics.isNotEmpty,
          destination: resource.destinationState,
        ),
      ],
    );
  }

  void _requireEntry(WorkEntryId entry) {
    if (entry != this.entry) {
      throw StateError("The document work entry belongs to another driver");
    }
  }

  @override
  Future<void> save(WorkEntryId entry) async {
    _requireEntry(entry);
    await resource.source.flush();
  }

  @override
  bool discard(WorkEntryId entry) {
    _requireEntry(entry);
    if (!snapshot.entries.single.canDiscard) return false;
    resource.source.discardDraft();
    return true;
  }

  @override
  Future<void> retry(WorkEntryId entry) => save(entry);

  @override
  void dispose() {
    resource.source.removeListener(notifyListeners);
    resource
      ..listener = null
      ..destination = null;
    resource.source.dispose();
    super.dispose();
  }
}

extension _CanonicalSubmissionIdentity on String {
  String? get _canonicalSubmissionId =>
      RegExp(
        r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$",
      ).hasMatch(this)
      ? this
      : null;
}
