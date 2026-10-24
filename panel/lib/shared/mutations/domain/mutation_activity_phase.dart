import "package:typewriter_panel/typewriter_panel.dart";

/// Duration for confirmed submission feedback in the activity journal.
/// Unresolved work never expires automatically.
const savedFeedbackDuration = Duration(seconds: 5);

/// Highest priority activity state shown by the shared mutation surface.
///
/// Saving and attention can coexist. The resolver gives attention precedence
/// over ordinary draft and completion states, while retaining saving context.
enum MutationActivityPhase {
  idle,
  pending,
  saving,
  savingWithAttention,
  needsAttention,
  needsInput,
  drafts,
  saved;

  bool get isSaving => this == saving || this == savingWithAttention;

  /// Resolves one aggregate phase from submission and resource read models.
  ///
  /// A saving phase reflects active delivery. Attention reflects rejected,
  /// uncertain, failed, conflicting, or integration work and therefore wins
  /// over lower priority states. The method does not inspect mutable owners.
  static MutationActivityPhase resolve(
    Iterable<LocalWorkSubmissionState> submissions,
    Iterable<WorkEntryState> drafts,
  ) {
    final saving =
        submissions.any((entry) => entry.sending) ||
        drafts.any((entry) => entry.saving);
    final attention =
        submissions.any(
          (entry) =>
              !entry.sending &&
              entry.result != LocalWorkSubmissionResult.ready &&
              (entry.result != LocalWorkSubmissionResult.confirmed ||
                  entry.integrationFailed),
        ) ||
        drafts.any((entry) => entry.needsAttention);
    if (attention) return saving ? savingWithAttention : needsAttention;

    if (saving) return MutationActivityPhase.saving;
    if (drafts.any((entry) => entry.needsInput)) {
      return needsInput;
    }

    if (drafts.isNotEmpty) return MutationActivityPhase.drafts;

    if (submissions.any(
      (entry) => entry.result == LocalWorkSubmissionResult.ready,
    )) {
      return pending;
    }
    return submissions.isEmpty ? idle : saved;
  }
}
