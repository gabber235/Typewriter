import "package:typewriter_panel/typewriter_panel.dart";

/// Presents the actions derived by a bound editing owner.
final class ApplyControls extends HookWidget {
  const ApplyControls({required this.control, super.key});
  final EditControl control;
  @override
  Widget build(BuildContext context) {
    useListenable(control);
    final state = control.state;
    if (!state.showControls) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state.status != null)
          Semantics(liveRegion: true, child: Text(state.status!)),
        for (final diagnostic in state.diagnostics) Text(diagnostic.message),
        Wrap(
          spacing: context.spacing.space2,
          children: [
            if (state.canDiscard)
              TextButton(
                onPressed: control.discard,
                child: Text(
                  state.hasLaterEdits ? "Discard later edits" : "Discard",
                ),
              ),
            if (state.canRetry)
              TextButton(onPressed: control.retry, child: const Text("Retry")),
            if (state.hasSubmittedWork)
              TextButton(
                onPressed: control.refresh,
                child: const Text("Refresh"),
              ),
            FilledButton(
              onPressed: state.canApply ? control.apply : null,
              child: const Text("Apply"),
            ),
          ],
        ),
      ],
    );
  }
}
