import "package:typewriter_panel/typewriter_panel.dart";

/// Acquires view leases. Canonical observations belong to feature registration.
abstract interface class InspectionBindingScope {
  ValueEditing editor(ValueEditingRegistration registration);
}

/// Keeps editor views leased while an inspection graph is installed.
///
/// Driver identities deduplicate resource views. A refresh acquires its next
/// leases before commit releases the previous set, so rebuilding a graph does
/// not briefly dispose an otherwise idle driver. Rollback releases only the
/// prospective leases and destinations. Resource drafts remain in [workspace].
final class InspectionBindings implements InspectionBindingScope {
  InspectionBindings({LocalWorkCommands? workspace})
    : workspace = workspace ?? ScopedWorkSession(),
      _ownsWorkspace = workspace == null;
  final LocalWorkCommands workspace;
  final bool _ownsWorkspace;
  WorkDestination Function(Object identity)? destinationFor;
  Map<WorkDriverId, WorkLease> _installed = {};
  Map<EditOwner, String> _labels = {};
  Map<WorkDriverId, ValueEditing> _bindings = {};
  InspectionBindingRefresh? _refresh;
  Map<EditOwner, String> get labels => Map.unmodifiable(_labels);
  @override
  ValueEditing editor(ValueEditingRegistration registration) {
    final source = _bindings.putIfAbsent(
      registration.driverId,
      () => registration.acquire(workspace),
    );
    _installed.putIfAbsent(
      registration.driverId,
      () => workspace.lease(registration.driverId),
    );
    _labels[source] = registration.label;
    if (destinationFor case final destination?) {
      workspace.setDestination(
        registration.driverId,
        destination(registration.targetId),
      );
    }
    return source;
  }

  InspectionBindingRefresh beginRefresh() {
    if (_refresh != null) {
      throw StateError("An inspection refresh is already active");
    }
    return _refresh = InspectionBindingRefresh._(this);
  }

  void dispose() {
    _refresh?.rollback();
    for (final lease in _installed.values) {
      lease.release();
    }
    _installed.clear();
    _labels.clear();
    _bindings.clear();
    if (_ownsWorkspace) (workspace as ScopedWorkSession).dispose();
  }
}

/// Acquires the next leases before releasing the installed view.
final class InspectionBindingRefresh implements InspectionBindingScope {
  InspectionBindingRefresh._(this.registry);
  final InspectionBindings registry;
  final _leases = <WorkDriverId, WorkLease>{};
  final _bindings = <WorkDriverId, ValueEditing>{};
  final _destinations = <WorkDriverId, WorkDestination>{};
  final _labels = <EditOwner, String>{};
  bool _finished = false;
  Map<EditOwner, String> get labels => Map.unmodifiable(_labels);
  @override
  ValueEditing editor(ValueEditingRegistration registration) {
    if (_finished) throw StateError("This inspection refresh ended");
    final source = _bindings.putIfAbsent(
      registration.driverId,
      () => registration.acquire(registry.workspace),
    );
    _leases.putIfAbsent(
      registration.driverId,
      () => registry.workspace.lease(registration.driverId),
    );
    _labels[source] = registration.label;
    if (registry.destinationFor case final destination?) {
      _destinations.putIfAbsent(
        registration.driverId,
        () => destination(registration.targetId),
      );
    }
    return source;
  }

  void commit() {
    if (_finished) throw StateError("This inspection refresh ended");
    for (final entry in _destinations.entries) {
      registry.workspace.setDestination(entry.key, entry.value);
    }
    final previous = registry._installed;
    registry
      .._installed = _leases
      .._labels = _labels
      .._bindings = _bindings
      .._refresh = null;
    _finished = true;
    for (final lease in previous.values) {
      lease.release();
    }
  }

  void rollback() {
    if (_finished) return;
    _finished = true;
    for (final destination in _destinations.values) {
      destination.dispose();
    }
    for (final lease in _leases.values) {
      lease.release();
    }
    registry._refresh = null;
  }

  void dispose() => rollback();
}
