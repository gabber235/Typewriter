import "package:typewriter_panel/typewriter_panel.dart";

/// Global widget that bridges interaction modes with the managed action system.
///
/// This widget watches the current interaction mode and automatically extracts
/// shortcuts from modes that implement [ModeShortcut], passing them to the
/// [ManagedActionSet] system for registration and display.
///
/// Place this above the surfaces that should receive the current mode's
/// shortcuts. The subtree must own focus for [ManagedActionSet] to activate its
/// actions. Interaction suspension deliberately supplies an empty action set.
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

  /// Dismisses what the focused widget can dismiss below its nearest
  /// [GlobalModeShortcut], the way Escape does without a mode.
  ///
  /// Returns whether an enabled [DismissIntent] action took the key. A
  /// disabled one, such as a page route's, leaves the key to the mode.
  static bool dismissFocused() {
    final context = primaryFocus?.context;
    if (context == null) return false;
    const intent = DismissIntent();
    Action<Intent>? nearest;
    context.visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is GlobalModeShortcut) return false;
      if (widget is Actions) nearest = widget.actions[DismissIntent];
      return nearest == null;
    });
    final action = nearest;
    if (action == null) return false;
    final (enabled, _) = Actions.of(context)
        .invokeActionIfEnabled(action, intent, context);
    return enabled;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(interactionSuspendedProvider)) {
      return ManagedActionSet(shortcuts: [], child: child);
    }

    final currentMode = ref.watch(currentInteractionModeProvider);

    final shortcuts = currentMode is ModeShortcut
        ? currentMode.getShortcuts()
        : <ActionShortcut>[];

    return ManagedActionSet(shortcuts: shortcuts, child: child);
  }
}
