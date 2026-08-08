import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

mixin DirectionalInteractionMode on InteractionMode {
  Intent intentForDirection(TraversalDirection direction);
}

void invokeCurrentModeDirection(WidgetRef ref, TraversalDirection direction) {
  final mode = ref.read(currentInteractionModeProvider);
  if (mode is! DirectionalInteractionMode) return;
  final focusContext = FocusManager.instance.primaryFocus?.context;
  if (focusContext == null) return;
  Actions.invoke(focusContext, mode.intentForDirection(direction));
}
