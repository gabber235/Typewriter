import "package:typewriter_panel/typewriter_panel.dart";

/// Adds directional focus navigation to an [InteractionMode].
///
/// The mode supplies the intent so each mode can choose how directional input
/// is interpreted. The shared shortcut callback invokes that intent against
/// Flutter's primary focus context.
mixin DirectionalInteractionMode on InteractionMode {
  /// Creates the focus intent for [direction] in this mode.
  Intent intentForDirection(TraversalDirection direction);
}

/// Invokes the active mode's directional focus action when one is available.
///
/// This is intentionally a no op for modes without
/// [DirectionalInteractionMode] and when no widget currently owns primary
/// focus. It reads the provider at invocation time, preventing a shortcut from
/// acting on a mode that was replaced before the callback ran.
void invokeCurrentModeDirection(WidgetRef ref, TraversalDirection direction) {
  final mode = ref.read(currentInteractionModeProvider);
  if (mode is! DirectionalInteractionMode) return;
  final focusContext = FocusManager.instance.primaryFocus?.context;
  if (focusContext == null) return;
  Actions.invoke(focusContext, mode.intentForDirection(direction));
}
