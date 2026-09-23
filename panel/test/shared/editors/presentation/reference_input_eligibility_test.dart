import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("reference selector waits for Realm and accepts Realm override", (
    tester,
  ) async {
    final response = Completer<ReferenceCandidateDecision>();
    final editor = _referenceEditor(
      evaluator: ReferenceEligibilityEvaluator(
        version: "1",
        evaluate: (_) => response.future,
      ),
    );
    addTearDown(editor.owner.dispose);
    await tester.pumpTestApp(child: editor.widget);

    await tester.tap(find.bySemanticsLabel("Activate search input"));
    await tester.pumpAndSettle();
    final result = find.ancestor(
      of: find.text("Candidate"),
      matching: find.byType(InkWell),
    );
    expect(result, findsOneWidget);

    await tester.tap(result);
    await tester.pump();
    expect(editor.owner.value(DataPath.root).valueOrNull, _initialReference);

    response.complete(const ReferenceCandidateDecision.allowed());
    await tester.pumpAndSettle();
    await tester.tap(result);
    await tester.pumpAndSettle();

    expect(editor.owner.value(DataPath.root).valueOrNull, _candidateReference);
  });

  testWidgets("pending reference drop cannot mutate the editor", (
    tester,
  ) async {
    final editor = _referenceEditor(
      evaluator: ReferenceEligibilityEvaluator(
        version: "1",
        evaluate: (_) => Completer<ReferenceCandidateDecision>().future,
      ),
    );
    addTearDown(editor.owner.dispose);
    await tester.pumpTestApp(child: editor.widget);
    final target = tester.widget<DragTarget<Object>>(
      find.byWidgetPredicate((widget) => widget is DragTarget<Object>),
    );
    final details = DragTargetDetails<Object>(
      data: const _ReferenceDragData(),
      offset: Offset.zero,
    );

    expect(target.onWillAcceptWithDetails?.call(details), isFalse);
    target.onAcceptWithDetails?.call(details);
    await tester.pump();

    expect(editor.owner.value(DataPath.root).valueOrNull, _initialReference);
  });

  group("ReferenceEligibilityController", () {
    test("Realm approval replaces a local advisory denial", () async {
      final response = Completer<ReferenceCandidateDecision>();
      final controller = ReferenceEligibilityController(
        ReferenceEligibilityEvaluator(
          version: "catalog:1 drafts:1",
          evaluate: (_) => response.future,
        ),
      );
      final evaluation = _evaluation();
      const local = ReferenceCandidateDecision.rejected(
        ReferencePolicyIssue(code: "local", message: "Local advisory denial"),
      );

      expect(
        controller.evaluate(evaluation, local, changed: () {}),
        isA<ReferenceCandidateUnavailable>(),
      );
      response.complete(const ReferenceCandidateDecision.allowed());
      await Future<void>.delayed(Duration.zero);

      expect(
        controller.evaluate(evaluation, local, changed: () {}),
        isA<ReferenceCandidateAllowed>(),
      );
    });

    test(
      "an unrelated draft version invalidates cached authorization",
      () async {
        var calls = 0;
        Future<ReferenceCandidateDecision> authorize(
          ReferenceEligibilityEvaluation _,
        ) async {
          calls++;
          return const ReferenceCandidateDecision.allowed();
        }

        final controller = ReferenceEligibilityController(
          ReferenceEligibilityEvaluator(
            version: "catalog:1 drafts:1",
            evaluate: authorize,
          ),
        );
        final evaluation = _evaluation();
        controller.evaluate(
          evaluation,
          const ReferenceCandidateDecision.allowed(),
          changed: () {},
        );
        await Future<void>.delayed(Duration.zero);
        expect(calls, 1);

        controller.updateEvaluator(
          ReferenceEligibilityEvaluator(
            version: "catalog:1 drafts:2",
            evaluate: authorize,
          ),
        );
        expect(
          controller.evaluate(
            evaluation,
            const ReferenceCandidateDecision.allowed(),
            changed: () {},
          ),
          isA<ReferenceCandidateUnavailable>(),
        );
        await Future<void>.delayed(Duration.zero);
        expect(calls, 2);
      },
    );

    test(
      "a catalog generation change invalidates cached authorization",
      () async {
        var calls = 0;
        Future<ReferenceCandidateDecision> authorize(
          ReferenceEligibilityEvaluation _,
        ) async {
          calls++;
          return const ReferenceCandidateDecision.allowed();
        }

        final controller = ReferenceEligibilityController(
          ReferenceEligibilityEvaluator(
            version: "catalog:1 drafts:1",
            evaluate: authorize,
          ),
        );
        final evaluation = _evaluation();
        controller.evaluate(
          evaluation,
          const ReferenceCandidateDecision.allowed(),
          changed: () {},
        );
        await Future<void>.delayed(Duration.zero);

        controller
          ..updateEvaluator(
            ReferenceEligibilityEvaluator(
              version: "catalog:2 drafts:1",
              evaluate: authorize,
            ),
          )
          ..evaluate(
            evaluation,
            const ReferenceCandidateDecision.allowed(),
            changed: () {},
          );
        await Future<void>.delayed(Duration.zero);
        expect(calls, 2);
      },
    );

    test("an older identical request cannot replace a newer request", () async {
      final oldResponse = Completer<ReferenceCandidateDecision>();
      final newResponse = Completer<ReferenceCandidateDecision>();
      final evaluation = _evaluation();
      final controller =
          ReferenceEligibilityController(
              ReferenceEligibilityEvaluator(
                version: "same",
                evaluate: (_) => oldResponse.future,
              ),
            )
            ..evaluate(
              evaluation,
              const ReferenceCandidateDecision.allowed(),
              changed: () {},
            )
            ..updateEvaluator(
              ReferenceEligibilityEvaluator(
                version: "same",
                evaluate: (_) => newResponse.future,
              ),
            )
            ..evaluate(
              evaluation,
              const ReferenceCandidateDecision.allowed(),
              changed: () {},
            );

      oldResponse.complete(
        const ReferenceCandidateDecision.rejected(
          ReferencePolicyIssue(code: "stale", message: "Stale denial"),
        ),
      );
      newResponse.complete(const ReferenceCandidateDecision.allowed());
      await Future<void>.delayed(Duration.zero);

      expect(
        controller.evaluate(
          evaluation,
          const ReferenceCandidateDecision.allowed(),
          changed: () {},
        ),
        isA<ReferenceCandidateAllowed>(),
      );
    });
  });
}

const _policyId = ReferencePolicyId("test.realmOverride");
final _initialReference = ReferenceValue(skir.ResourceId(value: "initial"));
final _candidateReference = ReferenceValue(skir.ResourceId(value: "candidate"));

({LocalEditor owner, Widget widget}) _referenceEditor({
  required ReferenceEligibilityEvaluator evaluator,
}) {
  final catalog = TypeCatalog(referenceResourceTypes.definitions);
  final owner = LocalEditor(
    rootType: ReferenceType(target: referenceResourceTypes.tag),
    typeCatalog: catalog,
    value: _initialReference,
  );
  final model = PresentationModel.editor(
    owner: owner,
    presentation: const PresentationNode(
      id: "reference",
      element: ReferenceInputElement(
        control: BoundControl(
          binding: BindingReference(bindingId: BindingId(0)),
        ),
        candidatePolicy: _policyId,
        rejectionDisplay: ReferenceRejectionDisplay.disabled,
      ),
    ),
  );
  return (
    owner: owner,
    widget: ComposedEditor(
      model: model,
      host: EditorHostCapabilities(
        references: ReferenceAuthoringCapabilities(
          search: ({required target, required origins, required registry}) =>
              _ReferenceSearchSource(),
          resolve: ({required target, required ids, required registry}) async =>
              [
                for (final id in ids)
                  ReferenceResourceSummary(id: id, exists: true, title: id.id),
              ],
          eligibility: evaluator,
          policies: ReferenceCandidatePolicyRegistry({
            _policyId: CallbackReferenceCandidatePolicy(
              (_) => const ReferenceCandidateDecision.rejected(
                ReferencePolicyIssue(
                  code: "local.deny",
                  message: "Local advisory denial",
                ),
              ),
            ),
          }),
        ),
      ),
    ),
  );
}

final class _ReferenceSearchSource implements SearchSource {
  final _snapshots = StreamController<SearchSourceSnapshot>.broadcast(
    sync: true,
  );

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  List<QuerySelectorDefinition> get selectors => const [];

  @override
  void initialize(SearchQueryContext context) => scheduleMicrotask(_emit);

  @override
  void search(SearchQueryContext context) => _emit();

  void _emit() {
    if (_snapshots.isClosed) return;
    _snapshots.add(
      SearchSourceSnapshot.ready(
        nodes: [
          SearchNode.result(
            result: SearchResult(
              id: "candidate",
              type: presentationSearchResultType,
              title: "Candidate",
              payload: PresentationSearchResultPayload(
                selectedValue: _candidateReference,
                presentation: PresentationNode(
                  id: "candidate",
                  element: TextElement("Candidate".asStringLiteral),
                ),
                expressions: const ExpressionContext(
                  bindings: BindingEnvironment({}),
                ),
                providerKey: "test.references",
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Future<SearchPreviewRequestResult> preview(
    SearchPreviewRequest request,
  ) async => const SearchPreviewRequestResult.error(message: "No preview");

  @override
  void dispose() => unawaited(_snapshots.close());
}

final class _ReferenceDragData implements ReferenceResourceDragData {
  const _ReferenceDragData();

  @override
  skir.ResourceId get referenceId => skir.ResourceId(value: "candidate");

  @override
  List<ResolvedTypeRef> get referenceTypes => [referenceResourceTypes.tag];
}

ReferenceEligibilityEvaluation _evaluation() => ReferenceEligibilityEvaluation(
  context: ReferenceCandidatePolicyContext(
    owner: null,
    path: DataPath.root.field("reference"),
    transition: ReferenceSelectionTransition.add,
    currentSelection: const {},
    candidate: ReferenceCandidate(id: skir.ResourceId(value: "candidate")),
  ),
  proposedValue: ReferenceValue(skir.ResourceId(value: "candidate")),
);
