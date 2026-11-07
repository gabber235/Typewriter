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
        for (final diagnostic in state.diagnostics)
          Text(diagnostic.message, style: context.text.sentence),
        Wrap(
          spacing: context.spacing.space2,
          children: [
            if (state.canDiscard)
              Button(
                label: state.hasLaterEdits ? "Discard later edits" : "Discard",
                onPressed: control.discard,
              ),
            if (state.canRetry)
              Button(label: "Retry", onPressed: control.retry),
            if (state.hasSubmittedWork)
              Button(label: "Refresh", onPressed: control.refresh),
            Button(
              face: ButtonFace.filled,
              label: "Apply",
              onPressed: state.canApply ? control.apply : null,
            ),
          ],
        ),
      ],
    );
  }
}
