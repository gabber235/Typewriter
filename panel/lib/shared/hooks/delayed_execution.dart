import "package:typewriter_panel/typewriter_panel.dart";

/// Runs [function] after the current widget tree has completed a frame.
///
/// With no [keys], the callback is scheduled after every rebuild. Supplying
/// keys makes scheduling follow the hook's normal dependency semantics, so the
/// callback runs again only when those keys change. The callback is deferred,
/// not executed during build.
void useDelayedExecution(Function function, [List<Object?>? keys]) =>
    use(_DelayedExecutionHook(function, keys: keys));

class _DelayedExecutionHook extends Hook<void> {
  const _DelayedExecutionHook(this.function, {super.keys});
  final Function function;

  @override
  _DelayedExecutionHookState createState() => _DelayedExecutionHookState();
}

class _DelayedExecutionHookState
    extends HookState<void, _DelayedExecutionHook> {
  void scheduleRun() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => hook.function(),
      debugLabel: debugLabel,
    );
  }

  @override
  void initHook() {
    super.initHook();
    scheduleRun();
  }

  @override
  void didUpdateHook(_DelayedExecutionHook oldHook) {
    super.didUpdateHook(oldHook);

    if (hook.keys == null) {
      scheduleRun();
    }
  }

  @override
  void build(BuildContext context) {}

  @override
  String debugLabel = "DelayedExecutionHook";

  @override
  bool get debugSkipValue => true;
}
