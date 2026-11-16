import "package:typewriter_panel/typewriter_panel.dart";

part "notices.g.dart";

/// How many toasts float at once; a newer one lands the oldest in Activity.
const maxToasts = 3;

/// The panel wide list of notices: the toasts that float and the failures
/// that wait in Activity.
///
/// Notices outlive routes, so a failure from one page is still in Activity
/// on the next. Only the shell's toaster lands toasts by time; everything
/// else reports, retries, dismisses or removes.
@Riverpod(keepAlive: true)
class Notices extends _$Notices {
  int _next = 0;

  @override
  List<Notice> build() => const [];

  /// Shows a toast for [title] and returns its id. A failure with [retry]
  /// offers Retry, in the toast and in Activity.
  int report({
    required String title,
    NoticeTone tone = NoticeTone.failure,
    String? detail,
    Future<void> Function()? retry,
  }) {
    final id = _next++;
    final floating = state.where((notice) => notice.toasting).toList();
    final landing = floating.length >= maxToasts
        ? floating.take(floating.length - maxToasts + 1).map((it) => it.id)
        : const <int>[];
    state = [
      for (final notice in state)
        if (!landing.contains(notice.id))
          notice
        else if (notice.tone == NoticeTone.failure)
          notice.copyWith(toasting: false),
      Notice(id: id, tone: tone, title: title, detail: detail, retry: retry),
    ];
    return id;
  }

  /// The toast of [id] ran out of time: a failure lands in Activity unread,
  /// a success is gone.
  void land(int id) => _toastEnds(id, read: false);

  /// The toast of [id] was dismissed by hand: a failure stays in Activity as
  /// read, a success is gone.
  void dismiss(int id) => _toastEnds(id, read: true);

  void _toastEnds(int id, {required bool read}) {
    state = [
      for (final notice in state)
        if (notice.id != id)
          notice
        else if (notice.tone == NoticeTone.failure &&
            notice.progress != NoticeProgress.resolved)
          notice.copyWith(toasting: false, read: notice.read || read),
    ];
  }

  /// Clears [id] from the toasts and from Activity.
  void remove(int id) => state = [
    for (final notice in state)
      if (notice.id != id) notice,
  ];

  /// Activity opened, so every failure in it has been seen.
  void readAll() {
    if (!state.any((notice) => notice.unread)) return;
    state = [for (final notice in state) notice.copyWith(read: true)];
  }

  /// Runs the retry of [id]. When it works the failure is resolved, and its
  /// toast or Activity entry shows that before it goes; when it fails again
  /// the failure keeps the new reason and counts the attempt.
  Future<void> retry(int id) async {
    final retry = _find(id)?.retry;
    if (retry == null || _find(id)?.progress != NoticeProgress.open) return;
    _update(id, (notice) => notice.copyWith(progress: NoticeProgress.retrying));
    try {
      await retry();
      _update(
        id,
        (notice) => notice.copyWith(progress: NoticeProgress.resolved),
      );
    } on Exception catch (error, stack) {
      final reason = failureMessage(error, stack);
      _update(
        id,
        (notice) => notice.copyWith(
          progress: NoticeProgress.open,
          detail: reason,
          attempts: notice.attempts + 1,
        ),
      );
    }
  }

  Notice? _find(int id) => state.where((notice) => notice.id == id).firstOrNull;

  void _update(int id, Notice Function(Notice) change) => state = [
    for (final notice in state)
      if (notice.id == id) change(notice) else notice,
  ];
}
