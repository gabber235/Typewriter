import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Mixin for interaction modes that need to display information in the app bar.
mixin ModeDisplay on InteractionMode {
  /// Builds a widget to display in the app bar for this mode.
  ///
  /// This method is called when the mode is active and needs to show
  /// visual feedback to the user about the current interaction context.
  Widget buildDisplay(BuildContext context);
}
