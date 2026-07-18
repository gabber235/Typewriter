import "package:flutter/material.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/interaction_mode/application/interaction_mode.dart";

/// Mixin for interaction modes that need to display information in the app bar.
mixin ModeDisplay on InteractionMode {
  /// Builds a widget to display in the app bar for this mode.
  ///
  /// This method is called when the mode is active and needs to show
  /// visual feedback to the user about the current interaction context.
  Widget buildDisplay(BuildContext context);
}
