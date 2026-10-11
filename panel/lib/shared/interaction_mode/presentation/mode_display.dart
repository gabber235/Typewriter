import "package:typewriter_panel/typewriter_panel.dart";

/// Projects the current mode's optional app bar display.
///
/// This widget watches `currentInteractionModeProvider` and delegates to
/// [ModeDisplay.buildDisplay] when the current mode implements that mixin. A
/// mode without the capability contributes a zero sized widget.
class ModeDisplayWidget extends ConsumerWidget {
  const ModeDisplayWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(currentInteractionModeProvider);

    if (currentMode is ModeDisplay) {
      return currentMode.buildDisplay(context);
    }

    return const SizedBox.shrink();
  }
}
