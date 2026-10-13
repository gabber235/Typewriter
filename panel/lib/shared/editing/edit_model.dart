import "package:typewriter_panel/typewriter_panel.dart";

part "edit_model.freezed.dart";

/// Stateless meaning of edits. The workspace owns every live operation.
abstract interface class EditModel<S, E> {
  EditObservationResult<S> acceptObservation(S known, S incoming);
  bool sameContract(S left, S right);
  bool isAvailable(S observation);
  EditReplay<S, E> replay(S onto, E edit);
  Iterable<EditRead<S>> reads(E edit);
  Set<Object> resources(S before, S after);
  bool hasEffect(S baseline, List<E> edits);
  List<EditorDiagnostic> validateCommit(S proposed);
  S publish(S observation, int revision);
  bool overlaps(E edit, Object interaction);
}

/// A captured semantic fact. Display reads never create these witnesses.
abstract interface class EditRead<S> {
  bool matches(S observation);
  bool differs(S before, S after);
}

/// Encodes one real server request from an immutable capture.
abstract interface class EditPersistence<S, E> {
  Set<Object> reservationsFor(Iterable<E> pendingEdits);
  Future<S> observeForCommit(S known);
  PreparedCommit<EditSettlement<S>> prepare(EditCapture<S, E> capture);
  Future<S> refresh();
}

enum EditReplayKind {
  applicable,
  satisfied,
  conflict,
  invalid,
  contractChanged,
  resourceMissing,
}

@freezed
abstract class EditReplay<S, E> with _$EditReplay<S, E> {
  const factory EditReplay({
    required EditReplayKind kind,
    required S observation,
    required E edit,
    @Default([]) List<EditorDiagnostic> diagnostics,
    EditConflictEvidence? conflict,
    Object? missing,
    Object? cause,
  }) = _EditReplay<S, E>;
}

enum EditObservationKind { accepted, stale, inconsistent }

@freezed
abstract class EditObservationResult<S> with _$EditObservationResult<S> {
  const factory EditObservationResult({
    required EditObservationKind kind,
    required S observation,
    String? message,
    @Default(true) bool changed,
  }) = _EditObservationResult<S>;
}

@freezed
abstract class EditCapture<S, E> with _$EditCapture<S, E> {
  const factory EditCapture({
    required EditGroupId group,
    required String label,
    required S baseline,
    required S proposed,
    required List<E> edits,
    required Set<int> operations,
  }) = _EditCapture<S, E>;
}

@freezed
sealed class EditSettlement<S> with _$EditSettlement<S> {
  const factory EditSettlement.confirmed(S observation) = EditConfirmed<S>;
  const factory EditSettlement.accepted() = EditAccepted<S>;
  const factory EditSettlement.conflict({
    required EditConflictEvidence evidence,
    S? observation,
  }) = EditConflict<S>;
  const factory EditSettlement.rejected({
    @Default([]) List<EditorDiagnostic> diagnostics,
    Object? cause,
    @Default(false) bool contractChanged,
  }) = EditRejected<S>;
}

@freezed
abstract class EditGroupId with _$EditGroupId {
  const factory EditGroupId(int value) = _EditGroupId;
}

@freezed
sealed class EditGroupPhase<S> with _$EditGroupPhase<S> {
  const factory EditGroupPhase.dirty() = EditGroupDirty<S>;
  const factory EditGroupPhase.awaitingDependency(Set<EditGroupId> groups) =
      EditGroupAwaitingDependency<S>;
  const factory EditGroupPhase.saving() = EditGroupSaving<S>;
  const factory EditGroupPhase.committedAwaitingRefresh(Object? cause) =
      EditGroupCommittedAwaitingRefresh<S>;
  const factory EditGroupPhase.conflict(
    String message,
    EditConflictEvidence? evidence,
  ) = EditGroupConflict<S>;
  const factory EditGroupPhase.rejected(String message, Object? cause) =
      EditGroupRejected<S>;
  const factory EditGroupPhase.contractChanged() = EditGroupContractChanged<S>;
  const factory EditGroupPhase.uncertain(Object cause) = EditGroupUncertain<S>;
  const factory EditGroupPhase.repeatedContention(
    int attempts,
    EditConflictEvidence? evidence,
  ) = EditGroupRepeatedContention<S>;
  const factory EditGroupPhase.resourceMissing(Object resource, S proposal) =
      EditGroupResourceMissing<S>;

  const EditGroupPhase._();
  bool get blocked =>
      this is! EditGroupDirty<S> &&
      this is! EditGroupAwaitingDependency<S> &&
      this is! EditGroupSaving<S>;
  bool get submitted =>
      this is EditGroupSaving<S> ||
      this is EditGroupCommittedAwaitingRefresh<S> ||
      this is EditGroupUncertain<S>;

  /// Applying changes and observing an acknowledged save are normal progress.
  bool get active => switch (this) {
    EditGroupSaving() || EditGroupCommittedAwaitingRefresh(cause: null) => true,
    _ => false,
  };

  /// Submission locks protect delivery independently of user recovery needs.
  bool get needsAttention => blocked && !active;

  String get message => switch (this) {
    EditGroupDirty() => "Changes await applying",
    EditGroupAwaitingDependency() =>
      "Waiting for related pending changes. Apply or discard that work first",
    EditGroupSaving() => "Applying",
    EditGroupCommittedAwaitingRefresh(cause: null) =>
      "Changes were applied. Refreshing saved values",
    EditGroupCommittedAwaitingRefresh() => "Changes were applied. Current values are unavailable; later edits remain local",
    EditGroupConflict(:final message) ||
    EditGroupRejected(:final message) => message,
    EditGroupContractChanged() =>
      "The editor contract changed. Review or discard pending work",
    EditGroupRepeatedContention() =>
      "The resource changed repeatedly. Retry when other edits stop",
    EditGroupUncertain() => "The outcome is unknown. Local work is retained and will not be resubmitted",
    EditGroupResourceMissing() =>
      "The resource was removed. Its proposal is retained for comparison",
  };
}

enum EditWriteAdmission {
  allowWhileSending,
  allowWhileSubmitted,
  lockWhileSubmitted,
}

enum EditRepairAdmission { preserveBlockedIntent, acceptCorrections }

enum EditObservationAdmission { rebase, reviewChanges }

@freezed
abstract class EditGroup<S> with _$EditGroup<S> {
  const factory EditGroup({
    required EditGroupId id,
    required String label,
    required EditorCommitPolicy policy,
    required EditGroupPhase<S> phase,
    required Set<Object> resources,
    required int operationCount,
    required S original,
  }) = _EditGroup<S>;
}

@freezed
abstract class EditingState<S> with _$EditingState<S> {
  const factory EditingState({
    S? confirmed,
    S? working,
    @Default({}) Map<EditGroupId, EditGroup<S>> groups,
    Object? failure,
    @Default(true) bool available,
  }) = _EditingState<S>;
}

@freezed
sealed class EditStageResult with _$EditStageResult {
  const factory EditStageResult.staged(EditGroupId group) = EditStaged;
  const factory EditStageResult.unchanged() = EditUnchanged;
  const factory EditStageResult.rejected(String message, Object? cause) =
      EditStageRejected;

  const EditStageResult._();
  void requireAccepted() {
    if (this case EditStageRejected(:final message)) throw StateError(message);
  }
}

extension EditStagePresentation on EditStageResult {
  void report(BuildContext context) {
    if (this case EditStageRejected(:final message)) {
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

/// Controls whether one invalid operation blocks its complete group.
enum EditCommitAdmission { completeGroup, applicableOperations }

/// An expected preparation rejection, retaining diagnostics for all consumers.
final class EditPreparationFailure implements Exception {
  const EditPreparationFailure(this.message, [this.diagnostics = const []]);
  final String message;
  final List<EditorDiagnostic> diagnostics;
  @override
  String toString() => message;
}

/// Domain evidence retained by the workspace without interpreting its protocol.
abstract interface class EditConflictEvidence {
  List<EditorDiagnostic> get diagnostics;
}

/// Captures one unsent group against its preceding journal state for review.
@freezed
abstract class EditGroupReview<S, E> with _$EditGroupReview<S, E> {
  const factory EditGroupReview({
    required S saved,
    required S original,
    required S beforeGroup,
    required S proposal,
    required Set<int> operations,
    required List<E> edits,
    @Default([]) List<EditConflictEvidence> conflicts,
    @Default([]) List<EditorDiagnostic> diagnostics,
  }) = _EditGroupReview<S, E>;
}
