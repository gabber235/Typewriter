import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "value_edit_model.freezed.dart";

/// Canonical interpretation metadata and the explicitly projected value.
@freezed
abstract class ValueEditDocument with _$ValueEditDocument {
  const factory ValueEditDocument({
    required EditorSnapshot metadata,
    required skir.DataValue value,
    Object? identity,
    @Default(true) bool exists,
  }) = _ValueEditDocument;
  const ValueEditDocument._();
  factory ValueEditDocument.fromSnapshot(
    EditorSnapshot snapshot, {
    Object? identity,
  }) => ValueEditDocument(
    metadata: snapshot,
    value: snapshot.document.confirmedValue,
    identity: identity,
  );
  int get revision => metadata.document.revision;
}

@freezed
abstract class ValueEdit with _$ValueEdit {
  const factory ValueEdit({
    required ValueEditDocument baseline,
    required skir.DataValue proposed,
    required Set<skir.ValuePath> paths,
    @Default([]) List<EditorSetValue> mutations,
  }) = _ValueEdit;
}

/// Pure path reconciliation. The workspace decides how results affect work.
final class ValueEditModel implements EditModel<ValueEditDocument, ValueEdit> {
  const ValueEditModel();
  @override
  EditObservationResult<ValueEditDocument> acceptObservation(
    ValueEditDocument known,
    ValueEditDocument incoming,
  ) {
    if (incoming.exists && !known.exists) {
      return EditObservationResult(
        kind: EditObservationKind.stale,
        observation: known,
      );
    }
    if (incoming.exists && incoming.revision < known.revision) {
      return EditObservationResult(
        kind: EditObservationKind.stale,
        observation: known,
      );
    }
    if (incoming.revision == known.revision &&
        incoming.value != known.value &&
        incoming.exists == known.exists) {
      return EditObservationResult(
        kind: EditObservationKind.inconsistent,
        observation: known,
        message: "Different values share the same revision",
      );
    }
    return EditObservationResult(
      kind: EditObservationKind.accepted,
      observation: incoming,
      changed:
          !known.metadata.document.hasSameMetadata(
            incoming.metadata.document,
          ) ||
          known.value != incoming.value ||
          known.exists != incoming.exists,
    );
  }

  @override
  bool isAvailable(ValueEditDocument observation) => observation.exists;
  @override
  bool sameContract(ValueEditDocument left, ValueEditDocument right) {
    final snapshot = left.metadata;
    return snapshot is EditorContractSnapshot
        ? snapshot.contractCompatibleWith(right.metadata)
        : left.metadata.document.rootType == right.metadata.document.rootType &&
              left.metadata.document.catalog.snapshot.generation ==
                  right.metadata.document.catalog.snapshot.generation;
  }

  @override
  EditReplay<ValueEditDocument, ValueEdit> replay(
    ValueEditDocument onto,
    ValueEdit edit,
  ) {
    if (!onto.exists) {
      return EditReplay(
        kind: EditReplayKind.resourceMissing,
        observation: onto,
        edit: edit,
        missing: onto.identity ?? editorRootPath,
      );
    }
    if (!sameContract(edit.baseline, onto)) {
      return EditReplay(
        kind: EditReplayKind.contractChanged,
        observation: onto,
        edit: edit,
      );
    }
    final result = const EditorReconciler().reconcile(
      base: edit.baseline.value,
      local: edit.proposed,
      remote: onto.value,
      remoteRevision: onto.revision,
      dirtyPaths: edit.paths,
      mergePolicies: onto.metadata.document.mergePolicies,
    );
    final observation = onto.copyWith(value: result.draft);
    final conflict = result.conflicts.values.firstOrNull;
    return EditReplay(
      kind: result.diagnostics.isNotEmpty
          ? EditReplayKind.invalid
          : conflict != null
          ? EditReplayKind.conflict
          : result.dirtyPaths.isEmpty
          ? EditReplayKind.satisfied
          : EditReplayKind.applicable,
      observation: observation,
      edit: conflict == null
          ? edit.copyWith(
              baseline: onto,
              proposed: result.draft,
              paths: result.dirtyPaths,
            )
          : edit,
      conflict: result.conflicts.isEmpty
          ? null
          : ValueConflictEvidence(paths: result.conflicts),
      diagnostics: [
        ...result.diagnostics,
        if (conflict != null)
          EditorDiagnostic(
            code: EditorDiagnosticCode.mutationConflict,
            message: "The field changed elsewhere",
            path: result.conflicts.keys.first,
          ),
      ],
    );
  }

  @override
  Iterable<EditRead<ValueEditDocument>> reads(ValueEdit edit) => edit.paths.map(
    (path) => _ValueEditRead(path, edit.baseline.value.editorValueAt(path)),
  );
  @override
  Set<Object> resources(ValueEditDocument before, ValueEditDocument after) =>
      before.value == after.value ? {} : {before.identity ?? editorRootPath};
  @override
  bool hasEffect(ValueEditDocument baseline, List<ValueEdit> edits) {
    var working = baseline;
    for (final edit in edits) {
      final result = replay(working, edit);
      if (result.kind != EditReplayKind.applicable &&
          result.kind != EditReplayKind.satisfied) {
        return true;
      }
      working = result.observation;
    }
    return working.value != baseline.value;
  }

  @override
  List<EditorDiagnostic> validateCommit(ValueEditDocument proposed) => [
    ...proposed.metadata.document.diagnostics,
    if (proposed.metadata.document.readOnly || !proposed.exists)
      EditorDiagnostic(
        code: EditorDiagnosticCode.invalidValue,
        message: "The resource is unavailable for editing",
      ),
    ...proposed.metadata.validateDraft(proposed.value),
  ];
  @override
  ValueEditDocument publish(ValueEditDocument observation, int revision) =>
      observation;
  @override
  bool overlaps(ValueEdit edit, Object interaction) =>
      interaction is skir.ValuePath &&
      edit.paths.any((path) => path.overlaps(interaction));
}

final class _ValueEditRead implements EditRead<ValueEditDocument> {
  const _ValueEditRead(this.path, this.expected);
  final skir.ValuePath path;
  final skir.DataValue? expected;
  @override
  bool matches(ValueEditDocument observation) =>
      observation.value.editorValueAt(path) == expected;
  @override
  bool differs(ValueEditDocument before, ValueEditDocument after) =>
      before.value.editorValueAt(path) != after.value.editorValueAt(path);
}

extension EditingPathOverlap on skir.ValuePath {
  bool overlaps(skir.ValuePath other) {
    final count = segments.length < other.segments.length
        ? segments.length
        : other.segments.length;
    for (var index = 0; index < count; index++) {
      if (segments.elementAt(index) != other.segments.elementAt(index)) {
        return false;
      }
    }
    return true;
  }
}

/// Keeps value reconciliation and its existing boundary response together.
@freezed
abstract class ValueConflictEvidence
    with _$ValueConflictEvidence
    implements EditConflictEvidence {
  const factory ValueConflictEvidence({
    @Default({}) Map<skir.ValuePath, EditorPathConflict> paths,
    TypedMutationResult? response,
    @Default([]) List<EditorDiagnostic> diagnostics,
  }) = _ValueConflictEvidence;
  const ValueConflictEvidence._();

  int? get expectedVersion => switch (response) {
    MutationConflict(:final expectedRevision) => expectedRevision,
    _ => null,
  };
  int? get observedVersion => switch (response) {
    MutationConflict(:final actualRevision) => actualRevision,
    _ => null,
  };
}
