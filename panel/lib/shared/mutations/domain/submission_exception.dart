import "package:typewriter_panel/typewriter_panel.dart";

/// Signals that a mutation response could not establish delivery certainty.
///
/// The submission remains available for inspection and possible replay. This
/// exception is for callers that need a feature level mutation result, not a
/// generic transport error.
final class SubmissionException<T> implements Exception {
  const SubmissionException(this.submission);

  final MutationSubmission<T> submission;

  @override
  String toString() => "The operation result could not be confirmed";
}
