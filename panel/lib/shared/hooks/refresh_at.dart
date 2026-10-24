import "package:typewriter_panel/typewriter_panel.dart";

/// Rebuilds the widget when [refreshAt] is reached.
///
/// The hook owns one scheduled timer. Updating the target cancels the old
/// timer and schedules the new one; a target that is now or already past does
/// not schedule a refresh. Supply [now] when the clock must be controlled,
/// such as in a deterministic test.
void useRefreshAt(DateTime refreshAt, {DateTime Function()? now}) =>
    use(_RefreshAtHook(refreshAt, now ?? DateTime.now));

class _RefreshAtHook extends Hook<void> {
  const _RefreshAtHook(this.refreshAt, this.now);

  final DateTime refreshAt;
  final DateTime Function() now;

  @override
  _RefreshAtHookState createState() => _RefreshAtHookState();
}

class _RefreshAtHookState extends HookState<void, _RefreshAtHook> {
  Timer? _timer;

  @override
  void initHook() {
    super.initHook();
    _scheduleRefresh();
  }

  @override
  void didUpdateHook(_RefreshAtHook oldHook) {
    super.didUpdateHook(oldHook);
    if (hook.refreshAt == oldHook.refreshAt && hook.now == oldHook.now) return;
    _scheduleRefresh();
  }

  void _scheduleRefresh() {
    _timer?.cancel();
    _timer = null;

    final delay = hook.refreshAt.difference(hook.now());
    if (delay <= Duration.zero) return;

    _timer = Timer(delay, () => setState(() {}));
  }

  @override
  void build(BuildContext context) {}

  @override
  void dispose() {
    _timer?.cancel();
  }

  @override
  String get debugLabel => "useRefreshAt";

  @override
  bool get debugSkipValue => true;
}
