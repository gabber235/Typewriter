import "package:typewriter_panel/typewriter_panel.dart";

/// Shows the current command outcome for the selected search result.
class SearchCommandInfo extends HookConsumerWidget {
  const SearchCommandInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(searchProvider)!;
    final state = controller.commandState;
    final commandId = switch (state) {
      SearchCommandIdle() => null,
      SearchCommandRunning(:final command) => command,
      SearchCommandCompleted(:final command) => command,
      SearchCommandFailed(:final command) => command,
    };
    final command = commandId == null ? null : controller.command(commandId);
    final presentation = command?.presentation;

    // One keyed Admonition; its icon stays the command's icon and its word
    // changes in place: Running, then Completed, types.
    final label = presentation?.label ?? "command";
    final previous = usePrevious(state);
    final failures = useRef(0);
    if (state is SearchCommandFailed && previous is! SearchCommandFailed) {
      failures.value++;
    }

    final child = switch (state) {
      SearchCommandIdle() => const SizedBox.shrink(key: ValueKey("idle")),
      SearchCommandRunning() => Admonition(
        key: const ValueKey("info"),
        color: presentation?.color ?? context.colors.info,
        icon: Icones(presentation?.icon ?? MaterialSymbols.play_arrow_rounded),
        child: MotionLabel("Running $label", rippling: true),
      ),
      SearchCommandCompleted() => Admonition(
        key: const ValueKey("info"),
        color: context.colors.success,
        icon: Icones(
          presentation?.icon ?? MaterialSymbols.check_circle_rounded,
        ),
        child: MotionLabel("Completed $label"),
      ),
      SearchCommandFailed(:final message) => Jam(
        key: const ValueKey("info"),
        failures: failures.value,
        child: Admonition(
          color: context.colors.danger,
          icon: Icones(presentation?.icon ?? Ic.round_dangerous),
          child: SelectableText("Failed $label: $message"),
        ),
      ),
    };

    return AnimatedSwitcher(
      duration: 750.ms,
      switchInCurve: Curves.linear,
      switchOutCurve: Curves.linear,
      transitionBuilder: (child, animation) =>
          ElasticTransition(animation: animation, child: child),
      child: child,
    );
  }
}
