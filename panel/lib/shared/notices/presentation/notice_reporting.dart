import "package:typewriter_panel/typewriter_panel.dart";

/// Reports notices from any widget under the panel's provider scope.
extension NoticeReporting on BuildContext {
  /// Toasts a failure titled [title] with its [detail]. It lands in Activity
  /// unless it is dismissed or [retry] makes it work.
  void reportFailure(
    String title, {
    String? detail,
    Future<void> Function()? retry,
  }) => _notices.report(title: title, detail: detail, retry: retry);

  /// Toasts a success titled [title]; it clears by itself and is not kept.
  void reportSuccess(String title) =>
      _notices.report(tone: NoticeTone.success, title: title);

  Notices get _notices => ProviderScope.containerOf(
    this,
    listen: false,
  ).read(noticesProvider.notifier);
}
