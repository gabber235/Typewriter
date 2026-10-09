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
    @Default([]) List<WorkEntryState> entries,
  }) = _WorkDriverSnapshot;
}

/// Whether a resource has a usable destination and whether it is visible.
enum LocalWorkDestinationState { unavailable, current, available }

/// Presentation state for one journaled mutation submission.
///
/// [result] describes delivery certainty. [integrationFailed] means the
/// mutation was confirmed but applying its response locally failed, so the
/// caller should refresh rather than resend the request.
@freezed
abstract class LocalWorkSubmissionState with _$LocalWorkSubmissionState {
  const factory LocalWorkSubmissionState({
    required Object id,
    required String label,
    required bool sending,
    required bool canReplay,
    required bool integrationFailed,
    required LocalWorkSubmissionResult result,
    String? message,
  }) = _LocalWorkSubmissionState;
}

/// Delivery states exposed by the mutation activity read model.
enum LocalWorkSubmissionResult {
  ready,
  confirmed,
  rejected,
  uncertain,
  notSubmitted,
}
