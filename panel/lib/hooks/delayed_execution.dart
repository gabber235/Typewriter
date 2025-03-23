import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";

/// Run code after the widget tree has build.
///
/// By default this is only ran on initialization.
/// But this can be changed to run every build.
void useDelayedExecution(Function function, {bool runEveryBuild = false}) =>
    use(_DelayedExecutionHook(function, runEveryBuild: runEveryBuild));

class _DelayedExecutionHook extends Hook<void> {
  const _DelayedExecutionHook(this.function, {required this.runEveryBuild});
  final Function function;
  final bool runEveryBuild;

  @override
  _DelayedExecutionHookState createState() => _DelayedExecutionHookState();
}

class _DelayedExecutionHookState
    extends HookState<void, _DelayedExecutionHook> {
  void _run() {
    WidgetsBinding.instance.addPostFrameCallback((_) => hook.function());
  }

  @override
  void initHook() {
    _run();
    super.initHook();
  }

  @override
  void build(BuildContext context) {
    if (hook.runEveryBuild) _run();
  }
}
