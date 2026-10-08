import "package:typewriter_panel/typewriter_panel.dart";

part "prepared_commit.freezed.dart";

/// One real persistence boundary, prepared before the shared owner sends it.
///
/// Capture request data and destination immutably. All attempts reuse that
/// input. [resources] defines the reservation boundary. [integrate] updates
/// local owners after a confirmed or rejected response and must never resend
/// the mutation. [dispose] releases dependencies retained for deferred work.
@freezed
abstract class PreparedCommit<T> with _$PreparedCommit<T> {
  const factory PreparedCommit({
    required Object id,
    required String label,
    required Future<SubmissionResult<T>> Function() send,
    Future<void> Function(SubmissionResult<T>)? integrate,
    void Function()? dispose,
    @Default({}) Set<Object> resources,
    @Default(SubmissionReplay.unsupported) SubmissionReplay replay,
  }) = _PreparedCommit<T>;
}
