import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "realm_edit_model.freezed.dart";
part "authoring_document.dart";
part "authoring_edit.dart";

/// Keeps local initialization findings with immutable prepared server intent.
@freezed
abstract class RealmPreparedEdit with _$RealmPreparedEdit {
  const factory RealmPreparedEdit({
    required skir.PreparedEdit request,
    @Default([]) List<skir.InitializationDiagnostic> findings,
  }) = _RealmPreparedEdit;
}

/// Pure authoring semantics. Resource and relation operations keep their facts.
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
    skir.EditExpectation? expected;
    skir.EditExpectation? actual;
    for (final fact in edit.request.expectations) {
      final observed = branch._actual(fact);
      if (!_sameExpectation(fact, observed)) {
        expected ??= fact;
        actual ??= observed;
      }
    }
    try {
      for (final intent in edit.request.intents) {
        if (branch._replay(intent) case final failure?) {
          throw StateError(failure);
        }
      }
      branch.requireValid();
      branch._initializationFindings.addAll(edit.findings);
      final observation = branch.toDocument();
      final effect =
          !const DeepCollectionEquality().equals(
            onto.entries,
            observation.entries,
          ) ||
          !const DeepCollectionEquality().equals(onto.links, observation.links);
      return EditReplay(
        kind: expected != null
            ? EditReplayKind.conflict
            : effect
            ? EditReplayKind.applicable
            : EditReplayKind.satisfied,
        observation: observation,
        edit: edit,
        expected: expected,
        actual: actual,
        diagnostics: expected == null
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
  bool matches(AuthoringDocument observation) => _sameExpectation(
    expected,
    AuthoringEdit.fromDocument(observation)._actual(expected),
  );
  @override
  bool differs(AuthoringDocument before, AuthoringDocument after) =>
      !_sameExpectation(
        AuthoringEdit.fromDocument(before)._actual(expected),
        AuthoringEdit.fromDocument(after)._actual(expected),
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
