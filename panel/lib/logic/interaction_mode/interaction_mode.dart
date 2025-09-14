/// Base abstract class for all interaction modes in the application.
/// Provides minimal core functionality that all modes must implement.
abstract class InteractionMode {
  const InteractionMode();

  /// The name of this interaction mode.
  /// Used for identification and debugging purposes.
  String get name;
}
