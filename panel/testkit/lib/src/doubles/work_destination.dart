import "package:typewriter_panel/typewriter_panel.dart";

/// A work destination that is never the current surface, opens nowhere and
/// counts how often it was disposed.
final class FakeWorkDestination extends WorkDestination {
  /// How often the destination was disposed.
  int disposals = 0;

  /// Called on every disposal.
  VoidCallback? onDispose;

  /// Whether the destination was disposed at least once.
  bool get disposed => disposals > 0;

  @override
  bool get isCurrent => false;

  @override
  Future<void> open() async {}

  @override
  void dispose() {
    disposals++;
    onDispose?.call();
    super.dispose();
  }
}
