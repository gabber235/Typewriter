import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "realm_edit_model.freezed.dart";
part "authoring_document.dart";
part "authoring_edit.dart";
part "authoring_facts.dart";
part "authoring_conflict_review.dart";

/// An atomic pair of saved facts and the working overlay sent for preparation.
@freezed
abstract class OperationWorkspaceCapture with _$OperationWorkspaceCapture {
  const factory OperationWorkspaceCapture({
    required AuthoringDocument document,
    required skir.OperationWorkingContext context,
    required int revision,
  }) = _OperationWorkspaceCapture;
}

/// Retains local intent, its preceding state witnesses, and initialization findings.
@freezed
abstract class RealmPreparedEdit with _$RealmPreparedEdit {
  const factory RealmPreparedEdit({
    required skir.PreparedEdit request,
    @Default([]) List<LocatedInitializationFinding> findings,
  }) = _RealmPreparedEdit;
}

/// Whether canonical relation metadata identifies one direct scalar counterpart.
@freezed
sealed class ResourceCounterpartResolution
    with _$ResourceCounterpartResolution {
  const factory ResourceCounterpartResolution.resolved(
    skir.ValueLocation location,
  ) = ResolvedResourceCounterpart;
  const factory ResourceCounterpartResolution.choiceRequired(String message) =
      ResourceCounterpartChoiceRequired;
  const factory ResourceCounterpartResolution.invalid(String message) =
      InvalidResourceCounterpart;
}

/// Supplies replay and composition semantics to the shared Realm editing workspace.
///
/// Replaying retains the original expectations while projecting intent onto a newer
/// observation. Conflicting facts remain explicit even when a working projection can
/// be produced. Composition checks that normalized intent reconstructs the reviewed
/// proposed content before preparing a saved request. This model performs no I/O;
/// persistence and local journal lifetime belong to their adjacent owners.
final class RealmEditModel
    implements EditModel<AuthoringDocument, RealmPreparedEdit> {
  const RealmEditModel();
  @override
  EditObservationResult<AuthoringDocument> acceptObservation(
    AuthoringDocument known,
    AuthoringDocument incoming,
  ) => EditObservationResult(
    kind: EditObservationKind.accepted,
    observation: incoming,
  );
  @override
  bool isAvailable(AuthoringDocument observation) => true;
  @override
  bool sameContract(AuthoringDocument left, AuthoringDocument right) =>
      left.generation == right.generation;
  @override
  EditReplay<AuthoringDocument, RealmPreparedEdit> replay(
    AuthoringDocument onto,
    RealmPreparedEdit edit,
  ) {
    final branch = AuthoringEdit.fromDocument(onto);
    if (edit.request.catalog != onto.generation) {
      return EditReplay(
        kind: EditReplayKind.contractChanged,
        observation: onto,
        edit: edit,
      );
    }
    final conflicts = onto.facts.conflicts(edit.request.expectations);
    try {
      for (final intent in edit.request.intents) {
        if (branch._replay(intent) case final failure?) {
          throw StateError(failure);
        }
      }
      branch.requireValid();
      branch._initializationFindings.addAll(edit.findings);
      final observation = branch.toDocument().copyWith(
        confirmedObservation: onto.confirmedObservation,
      );
      final effect =
          !const DeepCollectionEquality().equals(
            onto.entries,
            observation.entries,
          ) ||
          !const DeepCollectionEquality().equals(onto.links, observation.links);
      return EditReplay(
        kind: conflicts.isNotEmpty
            ? EditReplayKind.conflict
            : effect
            ? EditReplayKind.applicable
            : EditReplayKind.satisfied,
        observation: observation,
        edit: edit,
        conflict: conflicts.isEmpty
            ? null
            : AuthoringConflictEvidence(facts: conflicts),
        diagnostics: conflicts.isEmpty
            ? []
            : [
                EditorDiagnostic(
                  code: EditorDiagnosticCode.mutationConflict,
                  message: "The Realm changed before this edit was applied",
                ),
              ],
      );
    } on Object catch (error) {
      final missing = edit.request.expectations
          .whereType<skir.EditExpectation_resourceExistsWrapper>()
          .firstWhereOrNull(
            (fact) => fact.value.expected && onto.entry(fact.value.id) == null,
          )
          ?.value
          .id;
      return EditReplay(
        kind: missing == null
            ? EditReplayKind.invalid
            : EditReplayKind.resourceMissing,
        observation: onto,
        edit: edit,
        missing: missing,
        conflict: conflicts.isEmpty
            ? null
            : AuthoringConflictEvidence(facts: conflicts),
        cause: error,
        diagnostics: [
          EditorDiagnostic(
            code: EditorDiagnosticCode.mutationConflict,
            message: error.toString(),
          ),
        ],
      );
    }
  }

  RealmPreparedEdit compose(
    EditCapture<AuthoringDocument, RealmPreparedEdit> capture,
  ) {
    final branch = AuthoringEdit.fromDocument(capture.baseline);
    for (final operation in capture.edits) {
      branch.applyPrepared(operation.request);
      branch._initializationFindings.addAll(operation.findings);
    }
    final composed = branch.toDocument();
    if (!composed.hasSameAuthoredContent(capture.proposed)) {
      throw const EditPreparationFailure(
        "The prepared transaction differs from the reviewed changes",
      );
    }
    return branch.capture();
  }

  @override
  Iterable<EditRead<AuthoringDocument>> reads(RealmPreparedEdit edit) =>
      edit.request.expectations.map(_RealmEditRead.new);
  @override
  Set<Object> resources(AuthoringDocument before, AuthoringDocument after) => {
    for (final id in {...before.entries.keys, ...after.entries.keys})
      if (before.entry(id) != after.entry(id)) id,
  };
  @override
  bool hasEffect(AuthoringDocument baseline, List<RealmPreparedEdit> edits) {
    var working = baseline;
    for (final edit in edits) {
      final result = replay(working, edit);
      if (result.kind != EditReplayKind.applicable &&
          result.kind != EditReplayKind.satisfied) {
        return true;
      }
      working = result.observation;
    }
    return !const DeepCollectionEquality().equals(
          baseline.entries,
          working.entries,
        ) ||
        !const DeepCollectionEquality().equals(baseline.links, working.links);
  }

  @override
  List<EditorDiagnostic> validateCommit(AuthoringDocument proposed) {
    try {
      AuthoringEdit.fromDocument(proposed).requireValid();
      return [];
    } on Object catch (error) {
      return [
        EditorDiagnostic(
          code: EditorDiagnosticCode.invalidValue,
          message: error.toString(),
        ),
      ];
    }
  }

  @override
  AuthoringDocument publish(AuthoringDocument observation, int revision) =>
      observation.copyWith(revision: revision);
  @override
  bool overlaps(RealmPreparedEdit edit, Object interaction) =>
      edit.request.editedResources.contains(interaction);
}

final class _RealmEditRead implements EditRead<AuthoringDocument> {
  const _RealmEditRead(this.expected);
  final skir.EditExpectation expected;
  @override
  bool matches(AuthoringDocument observation) =>
      _sameExpectation(expected, observation.facts.observe(expected));
  @override
  bool differs(AuthoringDocument before, AuthoringDocument after) =>
      !_sameExpectation(
        before.facts.observe(expected),
        after.facts.observe(expected),
      );
}

extension RealmEditCapture on AuthoringEdit {
  RealmPreparedEdit capture() => RealmPreparedEdit(
    request: prepare(),
    findings: initializationFindings
        .skip(_inheritedFindings)
        .toList(growable: false),
  );
}

extension AuthoringContentComparison on AuthoringDocument {
  bool hasSameAuthoredContent(AuthoringDocument other) =>
      generation == other.generation &&
      const DeepCollectionEquality().equals(entries, other.entries) &&
      const SetEquality<skir.LinkProjection>().equals(
        links.toSet(),
        other.links.toSet(),
      ) &&
      const DeepCollectionEquality().equals(
        initializationFindings,
        other.initializationFindings,
      );
}

@freezed
abstract class AuthoringCompositionFailure
    with _$AuthoringCompositionFailure
    implements Exception {
  const factory AuthoringCompositionFailure(
    List<skir.ExpectationConflict> conflicts,
  ) = _AuthoringCompositionFailure;
}

/// Preserves every expected and actual fact returned by local or server checks.
@freezed
abstract class AuthoringConflictEvidence
    with _$AuthoringConflictEvidence
    implements EditConflictEvidence {
  const factory AuthoringConflictEvidence({
    required List<skir.ExpectationConflict> facts,
    @Default([]) List<EditorDiagnostic> diagnostics,
  }) = _AuthoringConflictEvidence;
}
