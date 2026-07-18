import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";

/// Run code after the widget tree has build.
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
    WidgetsBinding.instance
        .addPostFrameCallback((_) => hook.function(), debugLabel: debugLabel);
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
