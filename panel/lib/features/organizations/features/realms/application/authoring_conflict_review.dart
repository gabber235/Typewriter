part of "realm_edit_model.dart";

enum AuthoringConflictChoice { keepMine, useSaved }

/// Captures the exact proposal and observed facts that a user may resolve.
@freezed
abstract class AuthoringConflictReview with _$AuthoringConflictReview {
  const factory AuthoringConflictReview({
    required EditGroupId group,
    required Set<int> operations,
    required List<RealmPreparedEdit> edits,
    required AuthoringDocument saved,
    required AuthoringDocument original,
    required AuthoringDocument beforeGroup,
    required AuthoringDocument proposal,
    required List<skir.EditExpectation> reviewedFacts,
    required AuthoringConflictEvidence evidence,
    @Default([]) List<EditorDiagnostic> diagnostics,
  }) = _AuthoringConflictReview;
  const AuthoringConflictReview._();

  /// Includes the complete group proposal as well as its conflicting guards.
  List<skir.EditExpectation> get comparisonFacts {
    final facts = <Object, skir.EditExpectation>{};
    for (final operation in edits) {
      for (final expected in operation.request.expectations) {
        final before = original.facts.observe(expected);
        final proposed = proposal.facts.observe(expected);
        if (!_sameExpectation(before, proposed)) {
          facts.putIfAbsent(_factKey(expected), () => before);
        }
      }
    }
    for (final conflict in evidence.facts) {
      facts.putIfAbsent(
        _factKey(conflict.expected),
        () => original.facts.observe(conflict.expected),
      );
    }
    return List.unmodifiable(facts.values);
  }

  bool get canKeepMine => diagnostics.isEmpty;
  String? get unavailableReason => diagnostics.firstOrNull?.message;

  bool matches(EditGroupReview<AuthoringDocument, RealmPreparedEdit> current) =>
      saved.generation == current.saved.generation &&
      const SetEquality<int>().equals(operations, current.operations) &&
      const DeepCollectionEquality().equals(edits, current.edits) &&
      current.beforeGroup.facts.conflicts(reviewedFacts).isEmpty;
}

extension RealmConflictReview on RealmEditModel {
  AuthoringConflictReview review(
    EditGroupId id,
    EditGroupReview<AuthoringDocument, RealmPreparedEdit> current,
  ) {
    final facts = <Object, skir.EditExpectation>{};
    final observed = current.beforeGroup.facts;
    for (final operation in current.edits) {
      for (final expected in operation.request.expectations) {
        facts.putIfAbsent(_factKey(expected), () => observed.observe(expected));
      }
    }
    final conflicts = [
      for (final evidence
          in current.conflicts.whereType<AuthoringConflictEvidence>())
        ...evidence.facts,
    ];
    final diagnostics = [...current.diagnostics];
    if (current.edits.any(
      (edit) => edit.request.catalog != current.saved.generation,
    )) {
      diagnostics.add(
        const EditorDiagnostic(
          code: EditorDiagnosticCode.invalidValue,
          message: "The editor catalog changed. Make a new edit with the current form",
        ),
      );
    }
    if (conflicts.any(
      (conflict) =>
          conflict.expected is skir.EditExpectation_configurationWrapper,
    )) {
      diagnostics.add(
        const EditorDiagnostic(
          code: EditorDiagnosticCode.invalidValue,
          message: "The resource configuration changed. Make a new edit with the current form",
        ),
      );
    }
    return AuthoringConflictReview(
      group: id,
      operations: current.operations,
      edits: current.edits,
      saved: current.saved,
      original: current.original,
      beforeGroup: current.beforeGroup,
      proposal: current.proposal,
      reviewedFacts: facts.values.toList(),
      evidence: AuthoringConflictEvidence(facts: conflicts),
      diagnostics: diagnostics,
    );
  }

  RealmPreparedEdit resolveReviewed(
    AuthoringConflictReview reviewed,
    AuthoringDocument beforeGroup,
  ) {
    if (!reviewed.canKeepMine) {
      throw EditPreparationFailure(reviewed.unavailableReason!);
    }
    final branch = AuthoringEdit.fromDocument(beforeGroup);
    for (final operation in reviewed.edits) {
      final conflicts = branch.currentFacts.conflicts(
        operation.request.expectations,
      );
      for (final conflict in conflicts) {
        final approved = reviewed.evidence.facts.any(
          (fact) =>
              _sameExpectation(fact.expected, conflict.expected) &&
              _sameExpectation(fact.actual, conflict.actual),
        );
        if (!approved) {
          throw AuthoringCompositionFailure([conflict]);
        }
      }
      branch.applyPrepared(
        skir.PreparedEdit(
          catalog: operation.request.catalog,
          expectations: [
            for (final expected in operation.request.expectations)
              branch.currentFacts.observe(expected),
          ],
          intents: operation.request.intents,
        ),
      );
      branch._initializationFindings.addAll(operation.findings);
    }
    branch.requireValid();
    return branch.capture();
  }
}
