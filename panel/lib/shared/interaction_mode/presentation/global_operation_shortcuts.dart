import "package:flutter/widgets.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class GlobalOperationShortcuts extends ConsumerWidget {
  const GlobalOperationShortcuts({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(realmInteractionProvider).suspended) {
      return SelectionOperationShortcuts(enabled: false, child: child);
    }

    final currentMode = ref.watch(currentInteractionModeProvider);
    return SelectionOperationShortcuts(
      enabled: currentMode is NormalMode,
      child: child,
    );
  }
}
