import "package:typewriter_panel/typewriter_panel.dart";

/// Adds an app bar projection to an [InteractionMode].
///
/// [ModeDisplayWidget] renders this projection only while the implementing mode
/// is current. The returned widget is built in the consumer's context, so it
/// may use the active theme and shared design extensions.
mixin ModeDisplay on InteractionMode {
  /// Builds the mode's app bar projection for [context].
  ///
  /// The method is called during the current mode's presentation build. It
  /// should describe the mode, not own or change interaction mode state.
  Widget buildDisplay(BuildContext context);
}
