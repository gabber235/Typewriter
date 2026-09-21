import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

enum ReferenceSelectionTransition { add, remove, replace }

final class ReferenceCandidate {
  const ReferenceCandidate({required this.id, this.types = const []});

  final skir.ResourceId id;
  final List<ResolvedTypeRef> types;
}

final class ReferencePolicyIssue {
  const ReferencePolicyIssue({required this.code, required this.message});

  final String code;
  final String message;
}

sealed class ReferenceCandidateDecision {
  const ReferenceCandidateDecision();

  const factory ReferenceCandidateDecision.allowed() =
      ReferenceCandidateAllowed;
  const factory ReferenceCandidateDecision.rejected(
    ReferencePolicyIssue issue,
  ) = ReferenceCandidateRejected;
  const factory ReferenceCandidateDecision.unavailable(
    ReferencePolicyIssue issue,
  ) = ReferenceCandidateUnavailable;
}

final class ReferenceCandidateAllowed extends ReferenceCandidateDecision {
  const ReferenceCandidateAllowed();
}

final class ReferenceCandidateRejected extends ReferenceCandidateDecision {
  const ReferenceCandidateRejected(this.issue);

  final ReferencePolicyIssue issue;
}

final class ReferenceCandidateUnavailable extends ReferenceCandidateDecision {
  const ReferenceCandidateUnavailable(this.issue);

  final ReferencePolicyIssue issue;
}

final class ReferenceCandidatePolicyContext {
  const ReferenceCandidatePolicyContext({
    required this.owner,
    required this.path,
    required this.transition,
    required this.currentSelection,
    required this.candidate,
  });

  final EditOwner? owner;
  final DataPath path;
  final ReferenceSelectionTransition transition;
  final Set<skir.ResourceId> currentSelection;
  final ReferenceCandidate candidate;
}

final class ReferenceEligibilityEvaluation {
  const ReferenceEligibilityEvaluation({
    required this.context,
    required this.proposedValue,
    this.structuralMutation,
  });

  final ReferenceCandidatePolicyContext context;
  final DataValue proposedValue;
  final EditorStructuralMutation? structuralMutation;
}

/// Evaluates candidates against one immutable Realm authorization context.
///
/// [version] must change whenever the catalog generation or any submitted
/// local draft changes. Consumers use it to invalidate cached authorization
/// before applying a previously evaluated candidate.
final class ReferenceEligibilityEvaluator {
  const ReferenceEligibilityEvaluator({
    required this.version,
    required this.evaluate,
  });

  final Object version;
  final Future<ReferenceCandidateDecision> Function(
    ReferenceEligibilityEvaluation evaluation,
  )
  evaluate;

  Future<ReferenceCandidateDecision> call(
    ReferenceEligibilityEvaluation evaluation,
  ) => evaluate(evaluation);
}

abstract interface class ReferenceCandidatePolicy {
  ReferenceCandidateDecision evaluate(ReferenceCandidatePolicyContext context);
}

final class CallbackReferenceCandidatePolicy
    implements ReferenceCandidatePolicy {
  const CallbackReferenceCandidatePolicy(this.callback);

  final ReferenceCandidateDecision Function(
    ReferenceCandidatePolicyContext context,
  )
  callback;

  @override
  ReferenceCandidateDecision evaluate(
    ReferenceCandidatePolicyContext context,
  ) => callback(context);
}

final class CompositeReferenceCandidatePolicy
    implements ReferenceCandidatePolicy {
  const CompositeReferenceCandidatePolicy(this.policies);

  final List<ReferenceCandidatePolicy> policies;

  @override
  ReferenceCandidateDecision evaluate(ReferenceCandidatePolicyContext context) {
    for (final policy in policies) {
      final decision = policy.evaluate(context);
      if (decision is! ReferenceCandidateAllowed) return decision;
    }
    return const ReferenceCandidateDecision.allowed();
  }
}

final class ReferenceCandidatePolicyRegistry {
  const ReferenceCandidatePolicyRegistry([this.policies = const {}]);

  final Map<ReferencePolicyId, ReferenceCandidatePolicy> policies;

  ReferenceCandidateDecision evaluate(
    ReferencePolicyId? id,
    ReferenceCandidatePolicyContext context,
  ) {
    if (context.transition == ReferenceSelectionTransition.remove) {
      return const ReferenceCandidateDecision.allowed();
    }
    if (id == null) return const ReferenceCandidateDecision.allowed();
    final policy = policies[id];
    if (policy == null) {
      return ReferenceCandidateDecision.unavailable(
        ReferencePolicyIssue(
          code: "reference.policy.unavailable",
          message: "Reference policy '${id.value}' is unavailable",
        ),
      );
    }
    return policy.evaluate(context);
  }
}
