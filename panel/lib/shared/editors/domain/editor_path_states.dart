import "package:typewriter_panel/typewriter_panel.dart";

part "editor_path_states.freezed.dart";

/// Owns path level save progress and temporary interaction gates.
///
/// The editor source is the owner of this mutable index. It marks paths as
/// edits move through local draft, persistence, reconciliation, and recovery.
/// Queries include descendant records so a container can report the strongest
/// state affecting its visible subtree. Records disappear when no progress or
/// gate remains, preventing old status from leaking into a later edit.
///
/// Save phases are derived from live facts (dirty, saving, conflicted, and
/// related states) instead of recorded snapshots, so a path cannot report a
/// stale phase.
final class EditorPathStates {
  final Map<DataPath, EditorPathRecord> _records = {};
  final Map<DataPath, EditorContentionDetails> _contentions = {};

  Set<DataPath> get dirtyPaths => _pathsWhere((record) => record.dirty);

  bool get hasConflicts {
    return _records.values.any(
      (record) => record.progress is ConflictedPathProgress,
    );
  }

  /// Returns dirty paths eligible for the next persistence attempt.
  ///
  /// Conflict paths stay excluded until a caller resolves them. A non null
  /// request narrows the result without adding paths that are not dirty.
  Set<DataPath> flushCandidates(Set<DataPath>? requested) {
    final candidates = _pathsWhere(
      (record) => record.dirty && record.progress is! ConflictedPathProgress,
    );
    if (requested == null) return candidates;
    return candidates.intersection(requested);
  }

  Set<DataPath> get autoFlushCandidates {
    return _pathsWhere(
      (record) => record.progress is PendingPathProgress && record.gate == null,
    );
  }

  /// Summarizes the strongest state at [path] and all descendant paths.
  ///
  /// This is a read model for presentation and recovery. It does not mutate
  /// records or infer persistence from the current value.
  EditorSaveState saveState(DataPath path) {
    var best = const EditorSaveState.idle();
    var bestPriority = _phasePriority(best.phase);
    for (final entry in _records.entries) {
      if (!entry.key.isAtOrBelow(path)) continue;
      final candidate = entry.value.saveState(
        entry.key,
        contention: _contentions[entry.key],
      );
      final priority = _phasePriority(candidate.phase);
      if (priority <= bestPriority) continue;
      best = candidate;
      bestPriority = priority;
    }
    return best;
  }

  void markEdited(DataPath path) =>
      _setProgress(path, const EditorPathProgress.pending());

  void markSaving(Iterable<DataPath> paths) {
    for (final path in paths) {
      _setProgress(path, const EditorPathProgress.saving());
    }
  }

  void clearSaving() {
    for (final entry in _records.entries.toList()) {
      if (entry.value.progress is! SavingPathProgress) continue;
      _setProgress(entry.key, const EditorPathProgress.pending());
    }
  }

  void confirm(Iterable<DataPath> paths, EditorSavePhase phase) {
    for (final path in paths) {
      _setProgress(path, EditorPathProgress.settled(phase));
    }
  }

  void fail(Iterable<DataPath> paths, List<TypeDiagnostic> diagnostics) {
    for (final path in paths) {
      _setProgress(path, EditorPathProgress.failed(diagnostics));
    }
  }

  void markContended(
    Iterable<DataPath> paths,
    EditorContentionDetails contention,
  ) {
    for (final path in paths) {
      _contentions[path] = contention;
      _setProgress(path, const EditorPathProgress.contended());
    }
  }

  void resolveConflictLocally(DataPath path) =>
      _setProgress(path, const EditorPathProgress.pending());

  void adoptRemote(DataPath path, EditorSavePhase phase) =>
      _setProgress(path, EditorPathProgress.settled(phase));

  void reset(DataPath path) => _setProgress(path, null);

  /// Installs one reconciliation transition without losing settled paths.
  ///
  /// [dirtyPaths], [confirmedPaths], and [conflicts] are the result of one
  /// remote observation and must be applied together by the editor owner.
  void applyReconciliation({
    required Set<DataPath> dirtyPaths,
    required Set<DataPath> confirmedPaths,
    required Map<DataPath, EditorPathConflict> conflicts,
    required EditorSavePhase confirmedPhase,
  }) {
    for (final entry in _records.entries.toList()) {
      if (entry.value.progress is SettledPathProgress) continue;
      _setProgress(entry.key, null);
    }
    for (final path in dirtyPaths) {
      _setProgress(path, const EditorPathProgress.pending());
    }
    confirm(confirmedPaths, confirmedPhase);
    for (final entry in conflicts.entries) {
      _setProgress(entry.key, EditorPathProgress.conflicted(entry.value));
    }
  }

  EditorInteractionSession? gate(DataPath path) => _records[path]?.gate;

  void setGate(DataPath path, EditorInteractionSession session) =>
      _transform(path, (record) => record.copyWith(gate: session));

  void clearGate(DataPath path, EditorInteractionSession session) {
    if (_records[path]?.gate != session) return;
    _transform(path, (record) => record.copyWith(gate: null));
  }

  List<EditorInteractionSession> takeGates() {
    final gates = <EditorInteractionSession>[];
    for (final entry in _records.entries.toList()) {
      final gate = entry.value.gate;
      if (gate == null) continue;
      gates.add(gate);
      _transform(entry.key, (record) => record.copyWith(gate: null));
    }
    return gates;
  }

  Set<DataPath> _pathsWhere(bool Function(EditorPathRecord record) predicate) {
    return {
      for (final entry in _records.entries)
        if (predicate(entry.value)) entry.key,
    };
  }

  void _setProgress(DataPath path, EditorPathProgress? progress) {
    if (progress is! ContendedPathProgress) _contentions.remove(path);
    _transform(path, (record) => record.copyWith(progress: progress));
  }

  void _transform(
    DataPath path,
    EditorPathRecord Function(EditorPathRecord record) transform,
  ) {
    final next = transform(_records[path] ?? const EditorPathRecord());
    if (next.removable) {
      _records.remove(path);
    } else {
      _records[path] = next;
    }
  }
}

@freezed
abstract class EditorPathRecord with _$EditorPathRecord {
  const factory EditorPathRecord({
    EditorPathProgress? progress,
    EditorInteractionSession? gate,
  }) = _EditorPathRecord;

  const EditorPathRecord._();

  bool get removable => this.progress == null && gate == null;

  bool get dirty {
    return switch (this.progress) {
      PendingPathProgress() ||
      SavingPathProgress() ||
      FailedPathProgress() ||
      ContendedPathProgress() ||
      ConflictedPathProgress() => true,
      SettledPathProgress() || null => false,
    };
  }

  EditorSavePhase get phase {
    return switch (this.progress) {
      null => EditorSavePhase.idle,
      PendingPathProgress() => EditorSavePhase.pending,
      SavingPathProgress() => EditorSavePhase.saving,
      FailedPathProgress() => EditorSavePhase.failed,
      ContendedPathProgress() => EditorSavePhase.repeatedContention,
      ConflictedPathProgress() => EditorSavePhase.conflict,
      SettledPathProgress(:final phase) => phase,
    };
  }

  EditorSaveState saveState(
    DataPath path, {
    EditorContentionDetails? contention,
  }) {
    return EditorSaveState(
      phase: phase,
      path: path,
      conflict: switch (this.progress) {
        ConflictedPathProgress(:final conflict) => conflict,
        _ => null,
      },
      diagnostics: switch (this.progress) {
        FailedPathProgress(:final diagnostics) => diagnostics,
        _ => const [],
      },
      contention: contention,
    );
  }
}

@freezed
sealed class EditorPathProgress with _$EditorPathProgress {
  const factory EditorPathProgress.pending() = PendingPathProgress;

  const factory EditorPathProgress.saving() = SavingPathProgress;

  const factory EditorPathProgress.failed(List<TypeDiagnostic> diagnostics) =
      FailedPathProgress;

  const factory EditorPathProgress.contended() = ContendedPathProgress;

  const factory EditorPathProgress.conflicted(EditorPathConflict conflict) =
      ConflictedPathProgress;

  @Assert("phase == EditorSavePhase.saved", "A settled path has been saved.")
  const factory EditorPathProgress.settled(EditorSavePhase phase) =
      SettledPathProgress;
}

int _phasePriority(EditorSavePhase phase) => switch (phase) {
  EditorSavePhase.idle => 0,
  EditorSavePhase.saved => 1,
  EditorSavePhase.pending => 3,
  EditorSavePhase.saving => 4,
  EditorSavePhase.failed => 5,
  EditorSavePhase.uncertain => 9,
  EditorSavePhase.conflict => 6,
  EditorSavePhase.repeatedContention => 7,
  EditorSavePhase.deletedElsewhere => 8,
};
