import "package:typewriter_panel/typewriter_panel.dart";

/// Supplies readiness and change notifications for one family of route guards.
///
/// Implementations own their access state. Guards wait for [waitUntilReady],
/// then read the implementation's current decision. [reevaluation] emits only
/// when a previously stable decision may have changed, allowing the router to
/// reevaluate without reacting to transient loading states.
abstract interface class RouteAccessModule {
  /// Notifies the router when a stable access decision may have changed.
  Listenable get reevaluation;

  /// Completes after the first nonpending access state is available.
  Future<void> waitUntilReady();

  /// Releases state and resolves any pending readiness waiters.
  void dispose();
}
