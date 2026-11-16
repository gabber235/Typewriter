import "package:typewriter_panel/typewriter_panel.dart";

/// Projects the current mode's optional app bar display.
///
/// This widget watches `currentInteractionModeProvider` and shows the
/// [ModeChip] of the current mode's [ModeDisplay.look]. A mode without a look
/// contributes a zero sized widget.
class ModeDisplayWidget extends ConsumerWidget {
  const ModeDisplayWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(currentInteractionModeProvider);

    if (currentMode is ModeDisplay) {
      return ModeChip(look: currentMode.look(context));
    }

    return const SizedBox.shrink();
  }
}
