import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/interaction_mode/current_interaction_mode.dart";
import "package:typewriter_panel/logic/interaction_mode/mode_shortcut.dart";
import "package:typewriter_panel/widgets/app/components/action_shortcuts.dart";

/// Global widget that bridges interaction modes with the managed action system.
///
/// This widget watches the current interaction mode and automatically extracts
/// shortcuts from modes that implement [ModeShortcut], passing them to the
/// [ManagedActionSet] system for registration and display.
///
/// The widget should be placed high in the widget tree to ensure mode shortcuts
/// are available throughout the application.
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

  /// The child widget to wrap with mode shortcut functionality.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(currentInteractionModeProvider);

    final shortcuts = currentMode is ModeShortcut
        ? currentMode.getShortcuts()
        : <ActionShortcut>[];

    return ManagedActionSet(shortcuts: shortcuts, child: child);
  }
}
