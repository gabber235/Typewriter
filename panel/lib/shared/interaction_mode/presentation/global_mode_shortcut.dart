import "package:typewriter_panel/typewriter_panel.dart";

/// Global widget that bridges interaction modes with the managed action system.
///
/// This widget watches the current interaction mode and automatically extracts
/// shortcuts from modes that implement [ModeShortcut], passing them to the
/// [ManagedActionSet] system for registration and display.
///
/// Place this above the surfaces that should receive the current mode's
/// shortcuts. The subtree must own focus for [ManagedActionSet] to activate its
/// actions. Realm suspension deliberately supplies an empty action set.
///
/// Example usage:
/// ```dart
/// GlobalModeShortcut(
///   child: MaterialApp(
///     // ... app content
///   ),
/// )
/// ```
class GlobalModeShortcut extends ConsumerWidget {
  const GlobalModeShortcut({required this.child, super.key});

  /// The subtree whose focus and action context receive the mode shortcuts.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(realmInteractionProvider).suspended) {
      return ManagedActionSet(shortcuts: [], child: child);
    }

    final currentMode = ref.watch(currentInteractionModeProvider);

    final shortcuts = currentMode is ModeShortcut
        ? currentMode.getShortcuts()
        : <ActionShortcut>[];

    return ManagedActionSet(shortcuts: shortcuts, child: child);
  }
}
