import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The atomic outcome of comparing one local draft with a newer remote value.
///
/// `base` becomes the next canonical value and `draft` becomes the value shown
/// to the user. `revision` belongs to `base`. `dirtyPaths` are local choices
/// still requiring persistence, `confirmedPaths` are local choices already
/// accepted by the remote value, and `conflicts` preserve paths where both
/// sides changed different ways. Diagnostics report paths that could not be
/// applied safely. Consumers should install this result as one owner controlled
/// transition, never as unrelated field updates.
final class EditorReconciliationResult {
  const EditorReconciliationResult({
    required this.base,
    required this.draft,
    required this.revision,
    required this.dirtyPaths,
    required this.confirmedPaths,
    required this.conflicts,
    this.diagnostics = const [],
  });

  final skir.DataValue base;
  final skir.DataValue draft;
  final int revision;
  final Set<skir.ValuePath> dirtyPaths;
  final Set<skir.ValuePath> confirmedPaths;
  final Map<skir.ValuePath, EditorPathConflict> conflicts;
  final List<EditorDiagnostic> diagnostics;
}

/// Applies the editor's merge policy at every locally dirty path.
///
/// The comparison is three way: `base` is the last canonical value, `local`
/// is the unsaved draft, and `remote` is the newer canonical observation. An
/// unchanged remote path keeps the local edit. A remote value equal to local
/// confirms that edit. When both changed, `atomic` and `orderedList` conflict,
/// `record` descends by field, and `set` merges membership. Invalid paths are
/// retained as diagnostics instead of being silently discarded.
final class EditorReconciler {
  const EditorReconciler();

  EditorReconciliationResult reconcile({
    required skir.DataValue base,
    required skir.DataValue local,
    required skir.DataValue remote,
    required int remoteRevision,
    required Set<skir.ValuePath> dirtyPaths,
    required Map<skir.ValuePath, EditorMergePolicy> mergePolicies,
  }) {
    var draft = remote;
    final remaining = <skir.ValuePath>{};
    final confirmed = <skir.ValuePath>{};
    final conflicts = <skir.ValuePath, EditorPathConflict>{};
    final diagnostics = <EditorDiagnostic>[];

    for (final path in dirtyPaths) {
      final baseValue = base.editorValueAt(path);
      final localValue = local.editorValueAt(path);
      final remoteValue = remote.editorValueAt(path);
      if (baseValue == null || localValue == null || remoteValue == null) {
        diagnostics.add(_invalidPath(path));
        continue;
      }
      if (remoteValue == baseValue) {
        draft = _replace(draft, path, localValue, diagnostics);
        remaining.add(path);
        continue;
      }
      if (remoteValue == localValue) {
        confirmed.add(path);
        continue;
      }

      final policy = _policyFor(path, baseValue, mergePolicies);
      final merged = _merge(
        path: path,
        base: baseValue,
        local: localValue,
        remote: remoteValue,
        policy: policy,
        mergePolicies: mergePolicies,
      );

      draft = _replace(draft, path, merged.value, diagnostics);

      remaining.addAll(merged.dirtyPaths);
      conflicts.addAll(merged.conflicts);
    }

    return EditorReconciliationResult(
      base: remote,
      draft: draft,
      revision: remoteRevision,
      dirtyPaths: remaining,
      confirmedPaths: confirmed,
      conflicts: conflicts,
      diagnostics: diagnostics,
    );
  }

  _MergeResult _merge({
    required skir.ValuePath path,
    required skir.DataValue base,
    required skir.DataValue local,
    required skir.DataValue remote,
    required EditorMergePolicy policy,
    required Map<skir.ValuePath, EditorMergePolicy> mergePolicies,
  }) => switch (policy) {
    EditorMergePolicy.atomic ||
    EditorMergePolicy.orderedList => _conflict(path, base, local, remote),
    EditorMergePolicy.set => _mergeSet(path, base, local, remote),
    EditorMergePolicy.record => _mergeRecord(
      path,
      base,
      local,
      remote,
      mergePolicies,
    ),
  };

  _MergeResult _mergeRecord(
    skir.ValuePath path,
    skir.DataValue base,
    skir.DataValue local,
    skir.DataValue remote,
    Map<skir.ValuePath, EditorMergePolicy> policies,
  ) {
    final baseRecord = base.authoredRecord;
    final localRecord = local.authoredRecord;
    final remoteRecord = remote.authoredRecord;
    if (baseRecord == null || localRecord == null || remoteRecord == null) {
      return _conflict(path, base, local, remote);
    }
    final baseFields = {
      for (final field in baseRecord.fields) field.name: field.value,
    };
    final localFields = {
      for (final field in localRecord.fields) field.name: field.value,
    };
    final remoteFields = {
      for (final field in remoteRecord.fields) field.name: field.value,
    };
    final names = {
      ...baseFields.keys,
      ...localFields.keys,
      ...remoteFields.keys,
    };
    final fields = Map<String, skir.DataValue>.of(remoteFields);
    final dirty = <skir.ValuePath>{};

    final conflicts = <skir.ValuePath, EditorPathConflict>{};
    for (final name in names) {
      final childPath = path.field(name);
      final baseChild = baseFields[name];
      final localChild = localFields[name];
      final remoteChild = remoteFields[name];
      if (baseChild == null || localChild == null || remoteChild == null) {
        return _conflict(path, base, local, remote);
      }

      if (localChild == baseChild) continue;
      if (remoteChild == baseChild) {
        fields[name] = localChild;
        dirty.add(childPath);
        continue;
      }

      if (remoteChild == localChild) continue;
      final merged = _merge(
        path: childPath,
        base: baseChild,
        local: localChild,
        remote: remoteChild,
        policy: _policyFor(childPath, baseChild, policies),
        mergePolicies: policies,
      );

      fields[name] = merged.value;

      dirty.addAll(merged.dirtyPaths);
      conflicts.addAll(merged.conflicts);
    }
    return _MergeResult(
      value: skir.DataValue.createRecord(
        fields: [
          for (final entry in fields.entries)
            skir.FieldValue(name: entry.key, value: entry.value),
        ],
      ),
      dirtyPaths: dirty,
      conflicts: conflicts,
    );
  }

  _MergeResult _mergeSet(
    skir.ValuePath path,
    skir.DataValue base,
    skir.DataValue local,
    skir.DataValue remote,
  ) {
    final baseItems = base.authoredItems;
    final localItems = local.authoredItems;
    final remoteItems = remote.authoredItems;
    if (baseItems == null || localItems == null || remoteItems == null) {
      return _conflict(path, base, local, remote);
    }
    final ordered = [...localItems, ...remoteItems];
    final merged = <skir.ListItem>[];
    for (final candidate in ordered) {
      if (merged.any((item) => item.value == candidate.value)) continue;
      final inBase = baseItems.any((item) => item.value == candidate.value);
      final inLocal = localItems.any((item) => item.value == candidate.value);
      final inRemote = remoteItems.any((item) => item.value == candidate.value);

      final localChanged = inLocal != inBase;

      final present = localChanged ? inLocal : inRemote;
      if (present) merged.add(candidate);
    }
    return _MergeResult(
      value: skir.DataValue.createSetValue(items: merged),
      dirtyPaths: {path},
      conflicts: const {},
    );
  }

  _MergeResult _conflict(
    skir.ValuePath path,
    skir.DataValue base,
    skir.DataValue local,
    skir.DataValue remote,
  ) => _MergeResult(
    value: local,
    dirtyPaths: {path},
    conflicts: {
      path: EditorPathConflict(base: base, local: local, remote: remote),
    },
  );

  EditorMergePolicy _policyFor(
    skir.ValuePath path,
    skir.DataValue value,
    Map<skir.ValuePath, EditorMergePolicy> configured,
  ) {
    final selected = configured[path];
    if (selected != null) return selected;
    if (value.authoredRecord != null) return EditorMergePolicy.record;
    if (value.authoredItems != null) return EditorMergePolicy.orderedList;
    return EditorMergePolicy.atomic;
  }

  skir.DataValue _replace(
    skir.DataValue root,
    skir.ValuePath path,
    skir.DataValue value,
    List<EditorDiagnostic> diagnostics,
  ) {
    final replaced = root.replacingEditorValue(path, value);
    if (replaced == null) {
      diagnostics.add(_invalidPath(path));
      return root;
    }
    return replaced;
  }
}

final class _MergeResult {
  const _MergeResult({
    required this.value,
    required this.dirtyPaths,
    required this.conflicts,
  });

  final skir.DataValue value;
  final Set<skir.ValuePath> dirtyPaths;
  final Map<skir.ValuePath, EditorPathConflict> conflicts;
}

/// Describes a remote shape that cannot be applied at a locally tracked path.
EditorDiagnostic _invalidPath(skir.ValuePath path) => EditorDiagnostic(
  code: EditorDiagnosticCode.invalidPath,
  message: "Remote value cannot be reconciled at this path",
  path: path,
);
