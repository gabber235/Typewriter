import "package:typewriter_panel/typewriter_panel.dart";

part "local_work_state.freezed.dart";

/// Immutable read model published by the current local work session.
///
/// [resources] describes drafts with active work, [editorValues] exposes only
/// edited paths for projections, and [submissions] records mutation activity.
/// None of these collections is the authority for editor or submission state.
@freezed
abstract class LocalWorkState with _$LocalWorkState {
  const factory LocalWorkState({
    @Default({}) Map<EditorResourceKey, LocalWorkResourceState> resources,
    @Default({}) Map<EditorResourceKey, LocalEditorValue> editorValues,
    @Default([]) List<LocalWorkSubmissionState> submissions,
  }) = _LocalWorkState;
}

/// Presentation state for one resource that still has local work.
///
/// The save phase and diagnostics come from the editor source. [destination]
/// describes navigation availability, not whether the draft is persisted.
@freezed
abstract class LocalWorkResourceState with _$LocalWorkResourceState {
  const factory LocalWorkResourceState({
    required EditorResourceKey key,
    required String label,
    required EditorCommitPolicy commitPolicy,
    required EditorSavePhase savePhase,
    required bool readOnly,
    required bool hasDiagnostics,
    required LocalWorkDestinationState destination,
  }) = _LocalWorkResourceState;
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
