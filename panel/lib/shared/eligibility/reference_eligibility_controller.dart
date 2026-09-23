import "dart:async";

import "package:typewriter_panel/typewriter_panel.dart";

/// Caches Realm authorization only for one explicit evaluator version.
///
/// A unique token owns each pending request. Replacing an evaluator and then
/// evaluating the same candidate cannot let the older response consume or
/// overwrite the new request.
final class ReferenceEligibilityController {
  ReferenceEligibilityController(this._evaluator);

  ReferenceEligibilityEvaluator? _evaluator;
  final _results = <Object, ReferenceCandidateDecision>{};
  final _pending = <Object, int>{};
  var _nextToken = 0;

  void updateEvaluator(ReferenceEligibilityEvaluator? evaluator) {
    if (identical(_evaluator, evaluator) &&
        _evaluator?.version == evaluator?.version) {
      return;
    }
    _evaluator = evaluator;
    _results.clear();
    _pending.clear();
  }

  ReferenceCandidateDecision evaluate(
    ReferenceEligibilityEvaluation evaluation,
    ReferenceCandidateDecision local, {
    required void Function() changed,
  }) {
    final evaluator = _evaluator;
    if (evaluator == null) return local;
    final key = (
      evaluator.version,
      evaluation.context.owner,
      evaluation.context.path,
      evaluation.context.candidate.id,
      evaluation.context.transition,
      evaluation.proposedValue,
      _ownerRevision(evaluation.context.owner),
    );
    final result = _results[key];
    if (result != null) return result;
    if (!_pending.containsKey(key)) {
      final token = ++_nextToken;
      _pending[key] = token;
      unawaited(
        evaluator(evaluation).then(
          (decision) => _complete(
            evaluator: evaluator,
            key: key,
            token: token,
            decision: decision,
            changed: changed,
          ),
          onError: (Object error, StackTrace stackTrace) => _complete(
            evaluator: evaluator,
            key: key,
            token: token,
            decision: const ReferenceCandidateDecision.unavailable(
              ReferencePolicyIssue(
                code: "reference.eligibility.unavailable",
                message: "Reference eligibility is unavailable",
              ),
            ),
            changed: changed,
          ),
        ),
      );
    }
    return const ReferenceCandidateDecision.unavailable(
      ReferencePolicyIssue(
        code: "reference.eligibility.pending",
        message: "Checking reference eligibility",
      ),
    );
  }

  void _complete({
    required ReferenceEligibilityEvaluator evaluator,
    required Object key,
    required int token,
    required ReferenceCandidateDecision decision,
    required void Function() changed,
  }) {
    if (!identical(_evaluator, evaluator) || _pending[key] != token) return;
    _pending.remove(key);
    _results[key] = decision;
    changed();
  }
}

Object? _ownerRevision(EditOwner? owner) => switch (owner) {
  TransactionalEditorSource(:final localRevision, :final document) => (
    localRevision,
    document.revision,
  ),
  ProjectedEditOwner(:final owner) => _ownerRevision(owner),
  MultiEditOwner(:final owners) => Object.hashAll(owners.map(_ownerRevision)),
  _ => null,
};
