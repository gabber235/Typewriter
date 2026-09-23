import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  const policyId = ReferencePolicyId("test.policy");

  ReferenceCandidatePolicyContext context(
    ReferenceSelectionTransition transition,
  ) => ReferenceCandidatePolicyContext(
    owner: null,
    path: DataPath.root.field("target"),
    transition: transition,
    currentSelection: {skir.ResourceId(value: "current")},
    candidate: ReferenceCandidate(id: skir.ResourceId(value: "candidate")),
  );

  test("remove bypasses a missing policy", () {
    const registry = ReferenceCandidatePolicyRegistry();

    expect(
      registry.evaluate(policyId, context(ReferenceSelectionTransition.remove)),
      isA<ReferenceCandidateAllowed>(),
    );
  });

  test("missing policy is unavailable for additions", () {
    const registry = ReferenceCandidatePolicyRegistry();

    final decision = registry.evaluate(
      policyId,
      context(ReferenceSelectionTransition.add),
    );

    expect(decision, isA<ReferenceCandidateUnavailable>());
    expect(
      (decision as ReferenceCandidateUnavailable).issue.code,
      "reference.policy.unavailable",
    );
  });

  test("composition stops at the first non allowed decision", () {
    final evaluated = <String>[];
    final policy = CompositeReferenceCandidatePolicy([
      CallbackReferenceCandidatePolicy((context) {
        evaluated.add("first");
        return const ReferenceCandidateDecision.allowed();
      }),
      CallbackReferenceCandidatePolicy((context) {
        evaluated.add("second");
        return const ReferenceCandidateDecision.rejected(
          ReferencePolicyIssue(code: "blocked", message: "Blocked"),
        );
      }),
      CallbackReferenceCandidatePolicy((context) {
        evaluated.add("third");
        return const ReferenceCandidateDecision.allowed();
      }),
    ]);

    final decision = policy.evaluate(
      context(ReferenceSelectionTransition.replace),
    );

    expect(decision, isA<ReferenceCandidateRejected>());
    expect(evaluated, ["first", "second"]);
  });
}
