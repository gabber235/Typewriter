import "package:typewriter_panel/typewriter_panel.dart";

part "work_driver.freezed.dart";

/// Adapts a domain owner into the shared local work journal.
///
/// The driver owns draft and save policy and publishes its available commands
/// through [snapshot]. [ScopedWorkSession] owns registration, leases and disposal;
/// it retains a driver after its last view closes while entries still report
/// retained state or work. The journal does not infer a second domain lifecycle.
abstract interface class WorkDriver implements Listenable {
  WorkDriverId get id;
  WorkDriverSnapshot get snapshot;
  Future<void> save(WorkEntryId entry);
  bool discard(WorkEntryId entry);
  Future<void> retry(WorkEntryId entry);
  void dispose();
}

/// Retains one driver while a route or interaction uses its owned state.
final class WorkLease {
  WorkLease(this._release);
  VoidCallback? _release;

  void release() {
    final release = _release;
    _release = null;
    release?.call();
  }
}

/// Session owned registration joining a driver to its current navigation target.
///
/// Replacing [destination] disposes the previous target. Disposing this
/// registration releases both the target and driver, independently of leases.
final class OwnedWorkDriver {
  OwnedWorkDriver(this.driver, this.changed, {WorkDestination? destination}) {
    this.destination = destination;
  }
  final WorkDriver driver;
  final VoidCallback changed;
  WorkDestination? _destination;
  bool _disposed = false;
  int leases = 0;

  WorkDestination? get destination => _destination;
  set destination(WorkDestination? value) {
    if (_disposed) throw StateError("The work driver is disposed");
    if (identical(value, _destination)) return;
    final previous = _destination;
    _destination = null;
    previous?.removeListener(changed);
    previous?.dispose();
    if (_disposed) {
      value?.dispose();
      throw StateError("The work driver ended while its destination changed");
    }
    _destination = value;
    value?.addListener(changed);
  }

  bool get retained {
    final snapshot = driver.snapshot;
    return snapshot.entries.any((entry) => entry.retained || entry.hasWork);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    driver.removeListener(changed);
    _destination?.removeListener(changed);
    _destination?.dispose();
    _destination = null;
    driver.dispose();
  }
}

/// Optional view factory supplied by a feature registration.
abstract interface class WorkReviewProvider {
  WorkReviewContent? buildReview(WorkEntryId entry);
}

/// A disposable view. Its driver remains owned by the session.
@freezed
abstract class WorkReviewContent with _$WorkReviewContent {
  const factory WorkReviewContent({
    required Widget body,
    VoidCallback? dispose,
  }) = _WorkReviewContent;
}

/// Keeps the same driver alive while a retained work view is open.
final class WorkReviewLease {
  WorkReviewLease(this.content, this.lease);
  final WorkReviewContent content;
  final WorkLease lease;
  bool _closed = false;
  void release() {
    if (_closed) return;
    _closed = true;
    content.dispose?.call();
    lease.release();
  }
}
