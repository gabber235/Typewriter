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
  EditorMutationResult update(
    List<EditOwner> owners,
    skir.ValuePath path,
    skir.DataValue value, {
    EditorStructuralMutation? structuralMutation,
  }) {
    final holds = [
      for (final owner in owners)
        if (owner case final EditingStageOwner staged) staged.holdStage(),
    ];
    try {
      final validation = owners
          .map((owner) => owner.validate(path, value))
          .aggregateEditorMutationsFor(path);
      if (validation is! AppliedEditorMutation) return validation;
      final result = owners
          .map(
            (owner) => owner.update(
              path,
              validation.value,
              structuralMutation: structuralMutation,
            ),
          )
          .aggregateEditorMutationsFor(path);
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
      final interaction = session.interaction;
      interaction.close();
      if (interaction.workspace.policyFor(interaction.group) ==
          EditorCommitPolicy.autosaveChanges) {
        requests.add(interaction.workspace.applyRequest(interaction.group));
      }
    }
    await const EditApplyCoordinator().apply(requests);
  }
}
