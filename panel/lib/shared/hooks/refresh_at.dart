import "dart:async";

import "package:flutter/widgets.dart";
import "package:flutter_hooks/flutter_hooks.dart";

/// Rebuilds the widget using this hook when a future [refreshAt] is reached.
void useRefreshAt(DateTime refreshAt) => use(_RefreshAtHook(refreshAt));

class _RefreshAtHook extends Hook<void> {
  const _RefreshAtHook(this.refreshAt);

  final DateTime refreshAt;

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
    if (hook.refreshAt == oldHook.refreshAt) return;
    _scheduleRefresh();
  }

  void _scheduleRefresh() {
    _timer?.cancel();
    _timer = null;

    final delay = hook.refreshAt.difference(DateTime.now());
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
