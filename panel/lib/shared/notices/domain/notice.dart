import "package:typewriter_panel/typewriter_panel.dart";

part "notice.freezed.dart";

/// Whether a notice reports a failure, kept in Activity until handled, or a
/// success, which only toasts.
enum NoticeTone { failure, success }

/// Where a failure stands with its retry.
enum NoticeProgress { open, retrying, resolved }

/// One message the panel shows as a toast; failures stay in Activity.
///
/// [toasting] notices float as toasts. A failure that stops toasting lands in
/// Activity, unread until Activity opens or the toast was dismissed by hand.
/// [attempts] counts failed retries, so each one shakes the toast once.
@freezed
abstract class Notice with _$Notice {
  const factory Notice({
    required int id,
    required NoticeTone tone,
    required String title,
    String? detail,
    Future<void> Function()? retry,
    @Default(true) bool toasting,
    @Default(false) bool read,
    @Default(NoticeProgress.open) NoticeProgress progress,
    @Default(0) int attempts,
  }) = _Notice;

  const Notice._();

  /// Whether this failure waits in Activity for someone to read it.
  bool get unread =>
      tone == NoticeTone.failure &&
      !toasting &&
      !read &&
      this.progress != NoticeProgress.resolved;
}
