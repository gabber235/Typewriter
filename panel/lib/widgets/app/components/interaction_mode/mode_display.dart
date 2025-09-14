import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/interaction_mode/current_interaction_mode.dart";
import "package:typewriter_panel/logic/interaction_mode/mode_display.dart";

/// Widget that displays the current interaction mode in the app bar.
///
/// This widget watches the current interaction mode and displays the mode's
/// custom widget if it implements the ModeDisplay interface. If the current
/// mode doesn't implement ModeDisplay, the widget renders nothing.
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
