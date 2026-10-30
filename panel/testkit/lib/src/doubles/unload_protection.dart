import "package:typewriter_panel/typewriter_panel.dart";

/// A browser unload protection that records every protection state it is
/// set to, in order, and whether it was disposed.
final class RecordingUnloadProtection implements WorkSessionUnloadProtection {
  /// Every state the protection was set to, oldest first.
  final List<bool> values = [];

  /// Whether the protection was disposed.
  bool disposed = false;

  @override
  bool get protected => values.lastOrNull ?? false;

  @override
  set protected(bool value) => values.add(value);

  @override
  void dispose() => disposed = true;
}
