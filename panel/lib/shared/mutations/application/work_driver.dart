import "package:typewriter_panel/typewriter_panel.dart";

/// Owns domain state and projects its available commands without a second phase machine.
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
