import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

abstract interface class EditorOwnerScope {
  EditorSource editor(EditorTarget target);
}

/// Retains resource editors across presentation refreshes and disposes unused owners.
final class EditorOwnerRegistry implements EditorOwnerScope {
  EditorOwnerRegistry({LocalWorkCommands? workspace})
    : workspace = workspace ?? ScopedWorkSession(),
      _ownsWorkspace = workspace == null;

  final LocalWorkCommands workspace;
  final bool _ownsWorkspace;
  WorkDestination Function(Object identity)? destinationFor;
  Set<EditorResourceKey> _retained = {};
  EditorOwnerRefresh? _refresh;

  Map<EditOwner, String> get labels => labelsFor(_retained);

  Map<EditOwner, String> labelsFor(Iterable<EditorResourceKey> keys) => {
    for (final key in keys)
      if (workspace.resources[key] case final resource?)
        resource.source: resource.label,
  };

  @override
  EditorSource editor(EditorTarget target) {
    final source = workspace.editor(target);
    final key = target.resource.key;
    if (_retained.add(key)) workspace.retain(key);
    final destination = destinationFor;
    if (destination != null) {
      workspace.resources[key]!.destination = destination(target.targetId);
    }
    return source;
  }

  /// Starts one prospective owner set without disturbing the installed set.
  EditorOwnerRefresh beginRefresh() {
    if (_refresh != null) {
      throw StateError("An editor owner refresh is already active");
    }
    final refresh = EditorOwnerRefresh._(this, Set.unmodifiable(_retained));
    _refresh = refresh;
    return refresh;
  }

  void deleted(Object id) {
    final identity = id.resourceIdentity;
    for (final key in _retained) {
      if (key.identity == identity) {
        workspace.resources[key]?.source.acceptRemoteDeletion();
      }
    }
  }

  void unavailable(String message) {
    for (final key in _retained) {
      final source = workspace.resources[key]?.source;
      if (source == null) continue;
      source.refreshDocument(
        source.document.copyWith(
          readOnly: true,
          diagnostics: [
            EditorDiagnostic(
              code: EditorDiagnosticCode.invalidValue,
              message: message,
            ),
          ],
        ),
      );
    }
  }

  Future<Map<Object, TypedMutationResult>> flush({
    bool failedOnly = false,
  }) async {
    final selected = [
      for (final key in _retained)
        if (workspace.resources[key] case final resource?)
          if (!failedOnly || resource.source.saveState(editorRootPath).canRetry)
            resource,
    ];
    final results = await Future.wait(
      selected.map((entry) => entry.source.flush()),
    );
    return {
      for (var index = 0; index < selected.length; index++)
        selected[index].targetId: results[index],
    };
  }

  void dispose() {
    _refresh?.rollback();
    if (_ownsWorkspace) {
      (workspace as ScopedWorkSession).dispose();
      return;
    }
    for (final key in _retained) {
      workspace.release(key);
    }
    _retained.clear();
  }

  void _finish(EditorOwnerRefresh refresh, Set<EditorResourceKey>? next) {
    if (!identical(_refresh, refresh)) {
      throw StateError("The editor owner refresh is not active");
    }
    if (next != null) _retained = Set.of(next);
    _refresh = null;
  }
}

/// Owns editor leases and destinations for one prospective inspection model.
final class EditorOwnerRefresh implements EditorOwnerScope {
  EditorOwnerRefresh._(this._registry, this._previousKeys);

  final EditorOwnerRegistry _registry;
  final Set<EditorResourceKey> _previousKeys;
  final Set<EditorResourceKey> _nextKeys = {};
  final Set<EditorResourceKey> _newlyRetainedKeys = {};
  final Map<EditorResourceKey, WorkDestination> _nextDestinations = {};
  bool _finished = false;

  Map<EditOwner, String> get labels => _registry.labelsFor(_nextKeys);

  @override
  EditorSource editor(EditorTarget target) {
    _checkOpen();
    final source = _registry.workspace.editor(target);
    final key = target.resource.key;
    _nextKeys.add(key);
    if (!_previousKeys.contains(key) && _newlyRetainedKeys.add(key)) {
      _registry.workspace.retain(key);
    }
    final destinationFor = _registry.destinationFor;
    if (destinationFor != null && !_nextDestinations.containsKey(key)) {
      _nextDestinations[key] = destinationFor(target.targetId);
    }
    return source;
  }

  void commit() {
    _checkOpen();
    final installed = <EditorResourceKey>[];
    try {
      for (final entry in _nextDestinations.entries) {
        _registry.workspace.resources[entry.key]!.destination = entry.value;
        installed.add(entry.key);
      }
      for (final key in _previousKeys.difference(_nextKeys)) {
        _registry.workspace.release(key);
      }
      _finished = true;
      _registry._finish(this, _nextKeys);
    } on Object {
      for (final key in installed) {
        _registry.workspace.resources[key]?.destination = null;
      }
      rollback();
      rethrow;
    }
  }

  void rollback() {
    if (_finished) return;
    for (final key in _newlyRetainedKeys) {
      _registry.workspace.release(key);
    }
    for (final entry in _nextDestinations.entries) {
      if (_registry.workspace.resources[entry.key]?.destination !=
          entry.value) {
        entry.value.dispose();
      }
    }
    _finished = true;
    _registry._finish(this, null);
  }

  void dispose() => rollback();

  void _checkOpen() {
    if (_finished) throw StateError("The editor owner refresh has ended");
  }
}

/// Binds immutable presentation metadata to an explicitly scoped resource.
final class ResourceEditorTarget
    implements EditorTarget, PortablePresentationTarget {
  const ResourceEditorTarget({
    required this.targetId,
    required this.label,
    required this.resource,
    required this.snapshot,
    this.commitPolicy = EditorCommitPolicy.autosaveChanges,
    this.portablePresentation,
  });

  @override
  final Object targetId;

  @override
  final String label;

  @override
  final EditableResource resource;

  @override
  final EditorSnapshot snapshot;

  @override
  final EditorCommitPolicy commitPolicy;

  final PortablePresentationHostBuilder? portablePresentation;

  @override
  PortablePresentationHost? buildPortablePresentationHost(
    EditorSource source,
  ) => portablePresentation?.call(source);

  @override
  EditorDocument get document => snapshot.document;

  @override
  List<EditorDiagnostic> validateDraft(skir.DataValue value) =>
      snapshot.validateDraft(value);

  @override
  EditorValue value(skir.ValuePath path) =>
      document.confirmedValue.readEditorValue(path);

  @override
  EditorMutationResult validate(skir.ValuePath path, skir.DataValue value) =>
      snapshot.validate(path, value);
}

extension on Object {
  Object get resourceIdentity => switch (this) {
    SelectableIdentifier(:final resourceId) => resourceId,
    _ => this,
  };
}
