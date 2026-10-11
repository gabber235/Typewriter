import "package:typewriter_panel/typewriter_panel.dart";

part "local_work_state.freezed.dart";

/// Immutable read model published by the current local work session.
///
/// [entries] describes domain work, [editorValues] exposes only
/// edited paths for projections, and [submissions] records mutation activity.
/// None of these collections is the authority for editor or submission state.
@freezed
abstract class LocalWorkState with _$LocalWorkState {
  const factory LocalWorkState({
    @Default({}) Map<WorkEntryId, WorkEntryState> entries,
    @Default({}) Map<EditorResourceKey, LocalEditorValue> editorValues,
    @Default([]) List<LocalWorkSubmissionState> submissions,
  }) = _LocalWorkState;

  const LocalWorkState._();
  bool get blocksNavigation =>
      entries.values.any((entry) => entry.blocksNavigation);
}

/// Stable identity of one domain driver inside the authenticated scope.
@freezed
abstract class WorkDriverId with _$WorkDriverId {
  const factory WorkDriverId({required String domain, required Object scope}) =
      _WorkDriverId;
}

/// Identifies one entry using its driver and domain identity.
@freezed
abstract class WorkEntryId with _$WorkEntryId {
  const factory WorkEntryId({
    required WorkDriverId driver,
    required Object identity,
  }) = _WorkEntryId;
}

@freezed
abstract class WorkFact with _$WorkFact {
  const factory WorkFact({required String label, required String value}) =
      _WorkFact;
}

/// Display facts and commands projected once by the authoritative domain driver.
@freezed
abstract class WorkEntryState with _$WorkEntryState {
  const factory WorkEntryState({
    required WorkEntryId id,
    required String label,
    required String phase,
    @Default([]) List<WorkFact> details,
    @Default(false) bool retained,
    @Default(false) bool hasWork,
    @Default(false) bool canSave,
    @Default(false) bool canDiscard,
    @Default(false) bool canRetry,
    @Default(false) bool canReview,
    @Default(false) bool blocksNavigation,
    @Default(false) bool saving,
    @Default(false) bool needsAttention,
    @Default(false) bool needsInput,
    @Default(LocalWorkDestinationState.unavailable)
    LocalWorkDestinationState destination,
  }) = _WorkEntryState;
}

@freezed
abstract class WorkDriverSnapshot with _$WorkDriverSnapshot {
  const factory WorkDriverSnapshot({
    @Default({}) Map<EditorResourceKey, LocalEditorValue> editorValues,
    @Default([]) List<WorkEntryState> entries,
  }) = _WorkDriverSnapshot;
}

/// Whether a resource has a usable destination and whether it is visible.
enum LocalWorkDestinationState { unavailable, current, available }

/// Delivery and local integration are separate phases of one captured request.
@freezed
abstract class LocalWorkSubmissionState with _$LocalWorkSubmissionState {
  const factory LocalWorkSubmissionState({
    required Object id,
    required String label,
    required LocalWorkSubmissionPhase phase,
    @Default({}) Set<Object> resources,
  }) = _LocalWorkSubmissionState;
  const LocalWorkSubmissionState._();
  bool get sending => phase is ActiveLocalWorkSubmission;
  bool get integrationFailed =>
      phase is SettledLocalWorkSubmission &&
      (phase as SettledLocalWorkSubmission).integration
          is FailedLocalWorkIntegration;
  bool get canReplay => switch (phase) {
    UncertainLocalWorkSubmission(:final replay) =>
      replay == SubmissionReplay.identicalRequest,
    SettledLocalWorkSubmission(
      outcome: NotSubmittedLocalWorkOutcome(),
      integration: AppliedLocalWorkIntegration(),
    ) =>
      true,
    _ => false,
  };
  String? get message => switch (phase) {
    UncertainLocalWorkSubmission(:final message) => message,
    SettledLocalWorkSubmission(
      integration: FailedLocalWorkIntegration(:final message),
    ) =>
      message,
    SettledLocalWorkSubmission(
      outcome: RejectedLocalWorkOutcome(:final message) ||
          NotSubmittedLocalWorkOutcome(:final message),
    ) =>
      message,
    _ => null,
  };
  LocalWorkSubmissionResult get result => switch (phase) {
    PreparedLocalWorkSubmission() ||
    ActiveLocalWorkSubmission() => LocalWorkSubmissionResult.ready,
    UncertainLocalWorkSubmission() => LocalWorkSubmissionResult.uncertain,
    SettledLocalWorkSubmission(outcome: ConfirmedLocalWorkOutcome()) =>
      LocalWorkSubmissionResult.confirmed,
    SettledLocalWorkSubmission(outcome: RejectedLocalWorkOutcome()) =>
      LocalWorkSubmissionResult.rejected,
    SettledLocalWorkSubmission(outcome: NotSubmittedLocalWorkOutcome()) =>
      LocalWorkSubmissionResult.notSubmitted,
  };
}

@freezed
sealed class LocalWorkSubmissionPhase with _$LocalWorkSubmissionPhase {
  const factory LocalWorkSubmissionPhase.prepared() =
      PreparedLocalWorkSubmission;
  const factory LocalWorkSubmissionPhase.active() = ActiveLocalWorkSubmission;
  const factory LocalWorkSubmissionPhase.settled(
    LocalWorkKnownOutcome outcome,
    LocalWorkIntegration integration,
  ) = SettledLocalWorkSubmission;
  const factory LocalWorkSubmissionPhase.uncertain(
    String message,
    SubmissionReplay replay,
  ) = UncertainLocalWorkSubmission;
}

@freezed
sealed class LocalWorkKnownOutcome with _$LocalWorkKnownOutcome {
  const factory LocalWorkKnownOutcome.confirmed() = ConfirmedLocalWorkOutcome;
  const factory LocalWorkKnownOutcome.rejected(String message) =
      RejectedLocalWorkOutcome;
  const factory LocalWorkKnownOutcome.notSubmitted(String message) =
      NotSubmittedLocalWorkOutcome;
}

@freezed
sealed class LocalWorkIntegration with _$LocalWorkIntegration {
  const factory LocalWorkIntegration.applied() = AppliedLocalWorkIntegration;
  const factory LocalWorkIntegration.failed(String message) =
      FailedLocalWorkIntegration;
}

enum LocalWorkSubmissionResult {
  ready,
  confirmed,
  rejected,
  uncertain,
  notSubmitted,
}
