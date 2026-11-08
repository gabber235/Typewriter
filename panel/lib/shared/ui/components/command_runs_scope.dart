import "package:typewriter_panel/typewriter_panel.dart";

/// Owns the panel's one [CommandRuns]. Placed in AppRequiredWidgets inside
/// GlobalActionsManager, so every action set and row reaches it.
class CommandRunsScope extends HookConsumerWidget {
  const CommandRunsScope({required this.child, super.key});

  final Widget child;

  static CommandRuns of(BuildContext context) => maybeOf(context)!;

  /// Null outside the panel shell, as in a bare widget test of one row. The
  /// panel's one runner is these runs.
  static CommandRuns? maybeOf(BuildContext context) =>
      CommandRunnerScope.maybeOf(context) as CommandRuns?;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vsync = useTickerProvider();
    final controller = useMemoized(() => CommandRuns(vsync: vsync, scope: ref));
    useEffect(() => controller.dispose, [controller]);
    // Window blur or app switch is focus loss for every hold.
    useOnAppLifecycleStateChange((_, state) {
      if (state != AppLifecycleState.resumed) controller.release();
    });
    return CommandRunnerScope(runner: controller, child: child);
  }
}
