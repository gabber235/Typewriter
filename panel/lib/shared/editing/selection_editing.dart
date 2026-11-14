import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Defers publication until every local member has admitted the same change.
abstract interface class EditingStageOwner {
  EditingStageHold holdStage();
}

final class EditingStageHold {
  EditingStageHold({required this.rollback, required this._release});
  final VoidCallback rollback;
  VoidCallback? _release;
  void release() {
    final release = _release;
    _release = null;
    release?.call();
  }
}

/// Local admission is a cohort operation. Persistence keeps its real boundaries.
final class SelectionEditingCoordinator {
  const SelectionEditingCoordinator();

  /// Sets [value] at [path] on every owner, or on none of them.
  EditorMutationResult update(
    List<EditOwner> owners,
    skir.ValuePath path,
    skir.DataValue value,
  ) => _admitted(owners, () {
    final validation = owners
        .map((owner) => owner.validate(path, value))
        .aggregateEditorMutationsFor(path);
    if (validation is! AppliedEditorMutation) return (validation, null);
    return (
      null,
      () => owners
          .map((owner) => owner.update(path, validation.value))
          .aggregateEditorMutationsFor(path),
    );
  });

  /// Sets the value at the same index of [values] at [path] on each owner,
  /// or on none of them, as a set of choices changes one choice on items
  /// whose other choices differ.
  EditorMutationResult updateEach(
    List<EditOwner> owners,
    skir.ValuePath path,
    List<skir.DataValue> values,
  ) {
    if (values.length != owners.length) {
      throw ArgumentError.value(values, "values", "Needs one per owner");
    }
    return _admitted(owners, () {
      final validations = [
        for (final (index, owner) in owners.indexed)
          owner.validate(path, values[index]),
      ];
      final validation = validations._aggregateEach(path);
      if (validation is! AppliedEditorMutation) return (validation, null);
      return (
        null,
        () => [
          for (final (index, owner) in owners.indexed)
            owner.update(
              path,
              (validations[index] as AppliedEditorMutation).value,
            ),
        ]._aggregateEach(path),
      );
    });
  }

  /// Holds every owner's stage while [admit] validates the change, then
  /// applies it and rolls every owner back when one does not take it.
  EditorMutationResult _admitted(
    List<EditOwner> owners,
    (EditorMutationResult?, EditorMutationResult Function()?) Function() admit,
  ) {
    final holds = [
      for (final owner in owners)
        if (owner case final EditingStageOwner staged) staged.holdStage(),
    ];
    try {
      final (rejected, apply) = admit();
      if (rejected != null) return rejected;
      final result = apply!();
      if (result is! AppliedEditorMutation) {
        for (final hold in holds) {
          hold.rollback();
        }
      }
      return result;
    } finally {
      for (final hold in holds) {
        hold.release();
      }
    }
  }
}

extension on List<EditorMutationResult> {
  /// The results of a change that sets a different value on each owner:
  /// applied when every owner took its value, else what went wrong.
  EditorMutationResult _aggregateEach(skir.ValuePath path) {
    final invalid = whereType<InvalidEditorMutation>();
    if (invalid.isNotEmpty) {
      return EditorMutationResult.invalid([
        for (final result in invalid) ...result.diagnostics,
      ]);
    }
    if (any((result) => result is! AppliedEditorMutation)) {
      return const EditorMutationResult.conflict();
    }
    return first;
  }
}

extension SelectionInteractionCommit on Iterable<EditorInteractionSession> {
  Future<void> commitSelection() async {
    final sessions = toList(growable: false);
    if (sessions.isEmpty || sessions.every((session) => !session.active)) {
      return;
    }
    if (sessions.any((session) => !session.active)) {
      for (final session in sessions) {
        session.cancel();
      }
      return;
    }
    final prepared = sessions.whereType<ValueEditingInteraction>().toList();
    if (prepared.length != sessions.length) {
      throw StateError(
        "Selection persistence requires shared editing interactions",
      );
    }
    if (prepared.any((session) => !session.interaction.owned)) {
      for (final session in prepared) {
        session.cancel();
      }
      return;
    }
    final requests = <EditApplyRequest>[];
    for (final session in prepared) {
      final interaction = session.interaction..close();
      if (interaction.workspace.policyFor(interaction.group) ==
          EditorCommitPolicy.autosaveChanges) {
        requests.add(interaction.workspace.applyRequest(interaction.group));
      }
    }
    await const EditApplyCoordinator().apply(requests);
  }
}
