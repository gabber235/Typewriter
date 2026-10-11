import "package:typewriter_panel/typewriter_panel.dart";

part "submission_result.freezed.dart";

/// Delivery certainty is independent of the feature's response type.
///
/// Uncertain means execution may have happened. It must never be translated
/// into a rejection merely because the client did not receive a response.
@freezed
sealed class SubmissionResult<T> with _$SubmissionResult<T> {
  const factory SubmissionResult.confirmed(T value) = SubmissionConfirmed<T>;
  const factory SubmissionResult.rejected({
    required String message,
    Object? cause,
    T? response,
  }) = SubmissionRejected<T>;
  const factory SubmissionResult.notSubmitted({
    required String message,
    Object? cause,
  }) = SubmissionNotSubmitted<T>;
  const factory SubmissionResult.uncertain({
    required String message,
    required Object cause,
    required StackTrace stackTrace,
  }) = SubmissionUncertain<T>;
}

/// Declares whether an uncertain attempt may send the same captured request.
enum SubmissionReplay { unsupported, identicalRequest }
