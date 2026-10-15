import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

enum RealmInboxScenario {
  current,
  empty,
  ready,
  blocked,
  warnings,
  localDraft,
  largeReview,
  checking,
  publishing,
  unavailable,
  uncertain,
}

class RealmInboxStoryFixture extends ChangeNotifier {
  RealmInboxStoryFixture(this.scenario);
  RealmInboxScenario scenario;
  final scope = AuthoringScope(
    organizationId: skir.recordId("organization:story"),
    realmId: skir.recordId("service:story"),
  );
  final work = ScopedWorkSession();
  int published = 0;
  final root = skir.CompilationRoot(
    projection: skir.CompilationProjectionId(value: "typewriter.page"),
    resource: skir.ResourceId(value: "welcome"),
  );
  late final document = fixtureAuthoringDocument(
    pages: [
      Page(
        pageId: root.resource,
        bookId: null,
        name: "Arrival at Swan Harbor",
        configuration: skir.TypeSelection.unknown,
        chapter: "Arrival",
        priority: 0,
      ),
      for (var index = 0; index < 12; index++)
        Page(
          pageId: skir.ResourceId(value: "page_$index"),
          bookId: null,
          name: switch (index) {
            0 => "Meet the lighthouse keeper",
            1 => "A message in the bottle",
            _ => "Harbor dialogue ${index + 1}",
          },
          configuration: skir.TypeSelection.unknown,
          chapter: "Arrival",
          priority: index + 1,
        ),
    ],
  );
  skir.PublicationDiagnosticDetails get problem =>
      skir.PublicationDiagnosticDetails(
        evidence: null,
        id: skir.DiagnosticId(value: "missing_target"),
        origin: skir.RuleOrigin.defaultInstance,
        code: "missing_target",
        message: "Dialogue points to a missing page",
        primary: skir.ValueLocation(
          resource: root.resource,
          path: skir.ValuePath(segments: const []),
        ),
        related: const [],
      );
  skir.PublicationDelta get delta => skir.PublicationDelta(
    first: skir.PublicationChange.wrapRootUpdated(root),
    additional: scenario == RealmInboxScenario.largeReview
        ? [
            for (var index = 0; index < 12; index++)
              skir.PublicationChange.wrapRootAdded(
                skir.CompilationRoot(
                  projection: root.projection,
                  resource: skir.ResourceId(value: "page_$index"),
                ),
              ),
          ]
        : [
            skir.PublicationChange.wrapRootAdded(
              skir.CompilationRoot(
                projection: root.projection,
                resource: skir.ResourceId(value: "page_0"),
              ),
            ),
            skir.PublicationChange.wrapRootUpdated(
              skir.CompilationRoot(
                projection: root.projection,
                resource: skir.ResourceId(value: "page_1"),
              ),
            ),
          ],
  );
  List<skir.PublicationNotice> get notices =>
      scenario == RealmInboxScenario.warnings
      ? [skir.PublicationNotice.wrapWarning(problem)]
      : scenario == RealmInboxScenario.largeReview
      ? [
          for (var index = 0; index < 20; index++)
            skir.PublicationNotice.wrapWarning(
              skir.PublicationDiagnosticDetails(
                evidence: null,
                id: skir.DiagnosticId(value: "notice_$index"),
                origin: problem.origin,
                code: "dialogue_review",
                message: "Review dialogue ${index + 1} before release",
                primary: problem.primary,
                related: const [],
              ),
            ),
        ]
      : [];
  void select(RealmInboxScenario value) {
    scenario = value;
    notifyListeners();
  }

  RealmInboxState get state {
    final publication = switch (scenario) {
      RealmInboxScenario.current => RealmPublicationView.current(
        skir.PublicationStatus_Current(
          selected: skir.PublicationId(value: "selected"),
          notices: const [],
        ),
      ),
      RealmInboxScenario.empty => RealmPublicationView.empty(
        skir.PublicationStatus_Empty(notices: const []),
      ),
      RealmInboxScenario.ready ||
      RealmInboxScenario.largeReview ||
      RealmInboxScenario.warnings ||
      RealmInboxScenario.localDraft => RealmPublicationView.ready(
        skir.PublicationStatus_Ready(
          candidate: skir.PublicationCandidateId(value: "reviewed"),
          baseline: skir.PublicationBaseline.wrapSelected(
            skir.PublicationId(value: "selected"),
          ),
          changes: delta,
          notices: notices,
        ),
        RealmPublishCommand(
          skir.PublicationCandidateId(value: "reviewed"),
          () async {
            published++;
            select(RealmInboxScenario.current);
            return skir.PublicationResult.createActivated(
              publication: skir.PublicationId(value: "published"),
            );
          },
        ),
      ),
      RealmInboxScenario.blocked => RealmPublicationView.blocked(
        skir.PublicationStatus_Blocked(
          baseline: skir.PublicationBaseline.wrapSelected(
            skir.PublicationId(value: "selected"),
          ),
          blockers: skir.PublicationBlockers(
            first: skir.PublicationBlocker(details: problem),
            additional: const [],
          ),
          notices: const [],
          confirmedChanges: delta.additional,
          pendingRoots: [root],
        ),
      ),
      RealmInboxScenario.checking => const RealmPublicationView.checking(),
      RealmInboxScenario.publishing => RealmPublicationView.publishing(
        skir.PublicationStatus_Publishing(
          publication: skir.PublicationId(value: "publishing"),
          phase: skir.PublicationActivationPhase.activating,
          releasing: delta,
          next: skir.PublicationPendingReview(
            findings: const [],
            confirmedChanges: const [],
            pendingRoots: const [],
            blockers: const [],
            notices: const [],
          ),
        ),
      ),
      RealmInboxScenario.unavailable => const RealmPublicationView.unavailable(
        "The realm connection is unavailable. Try reconnecting.",
      ),
      RealmInboxScenario.uncertain => const RealmPublicationView.uncertain(
        "The reply was lost. Verify the selected release before trying again.",
      ),
    };
    return RealmInboxState(
      publication: publication,
      issues: [
        if (scenario == RealmInboxScenario.blocked)
          RealmInboxIssue.finding(
            problem.asResourceIssue(
              skir.DiagnosticSeverity.error,
              null,
              blocksPublication: true,
            ),
          ),
        if (scenario == RealmInboxScenario.warnings)
          RealmInboxIssue.finding(
            (notices.single as skir.PublicationNotice_warningWrapper).value
                .asResourceIssue(skir.DiagnosticSeverity.warning, null),
          ),
        if (scenario == RealmInboxScenario.largeReview)
          for (final notice in notices)
            RealmInboxIssue.finding(
              (notice as skir.PublicationNotice_warningWrapper).value
                  .asResourceIssue(skir.DiagnosticSeverity.warning, null),
            ),
        if (scenario == RealmInboxScenario.localDraft)
          RealmInboxIssue.finding(
            ResourceIssue(
              current: true,
              diagnostic: PortablePresentationDiagnostic(
                code: "required",
                message: "The draft dialogue needs a speaker",
                severity: skir.DiagnosticSeverity.error,
                targets: [
                  PortableDiagnosticTarget.value(
                    skir.ValueLocation(
                      resource: root.resource,
                      path: skir.ValuePath(segments: const []),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
      changes: publication is ReadyRealmPublication
          ? [delta.first, ...delta.additional]
          : publication is BlockedRealmPublication
          ? delta.additional.toList()
          : [],
      pendingRoots: scenario == RealmInboxScenario.blocked ? [root] : [],
    );
  }

  @override
  void dispose() {
    work.dispose();
    super.dispose();
  }
}
