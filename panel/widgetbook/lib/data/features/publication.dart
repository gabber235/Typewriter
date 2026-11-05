import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

/// The publication states the Realm reports for the showcase content, by
/// the name a story knob shows them under.
///
/// Each is a [publication] trait: the review the Realm offers and how it
/// answers when the user publishes.
Map<String, List<Trait>> get storyPublications => {
  "Ready": [publication(_available(_ready()))],
  "Everything published": [
    publication(
      _available(
        skir.PublicationStatus.wrapCurrent(
          skir.PublicationStatus_Current(
            selected: _selected,
            notices: const [],
          ),
        ),
      ),
    ),
  ],
  "Nothing published yet": [
    publication(
      _available(
        skir.PublicationStatus.wrapEmpty(
          skir.PublicationStatus_Empty(notices: const []),
        ),
      ),
    ),
  ],
  "Warnings": [
    publication(_available(_ready(notices: [_warning(0)]))),
  ],
  "Large review": [
    publication(
      _available(
        _ready(
          notices: [for (var index = 0; index < 20; index++) _warning(index)],
          large: true,
        ),
      ),
    ),
  ],
  "Blocked": [
    publication(
      _available(
        skir.PublicationStatus.wrapBlocked(
          skir.PublicationStatus_Blocked(
            baseline: skir.PublicationBaseline.wrapSelected(_selected),
            blockers: skir.PublicationBlockers(
              first: skir.PublicationBlocker(details: _problem),
              additional: const [],
            ),
            notices: const [],
            confirmedChanges: _delta().additional,
            pendingRoots: [_root("page:arrival")],
          ),
        ),
      ),
    ),
  ],
  "Publishing": [
    publication(
      _available(
        skir.PublicationStatus.wrapPublishing(
          skir.PublicationStatus_Publishing(
            publication: skir.PublicationId(value: "publishing"),
            phase: skir.PublicationActivationPhase.activating,
            releasing: _delta(),
            next: skir.PublicationPendingReview(
              findings: const [],
              confirmedChanges: const [],
              pendingRoots: const [],
              blockers: const [],
              notices: const [],
            ),
          ),
        ),
      ),
    ),
  ],
  "Unavailable": [
    publication(
      const PublicationObservation.unavailable(
        "The realm connection is unavailable. Try reconnecting.",
      ),
    ),
  ],
  "Reply lost": [publication(_available(_ready()), reply: PublishReply.lost)],
};

final _selected = skir.PublicationId(value: "selected");

PublicationObservation _available(skir.PublicationStatus status) =>
    PublicationObservation.available(
      skir.PublicationView(
        id: skir.PublicationViewId(value: "story"),
        status: status,
      ),
    );

skir.CompilationRoot _root(String resource) => skir.CompilationRoot(
  projection: skir.CompilationProjectionId(value: "typewriter.resource-graph"),
  resource: skir.ResourceId(value: resource),
);

const _pages = ["page:prologue", "page:market", "page:finale"];

skir.PublicationDelta _delta({bool large = false}) => skir.PublicationDelta(
  first: skir.PublicationChange.wrapRootUpdated(_root("page:arrival")),
  additional: [
    if (large)
      for (var index = 0; index < 12; index++)
        skir.PublicationChange.wrapRootAdded(_root("page:draft_$index"))
    else ...[
      skir.PublicationChange.wrapRootAdded(_root(_pages[0])),
      skir.PublicationChange.wrapRootUpdated(_root(_pages[1])),
    ],
  ],
);

skir.PublicationStatus _ready({
  List<skir.PublicationNotice> notices = const [],
  bool large = false,
}) => skir.PublicationStatus.wrapReady(
  skir.PublicationStatus_Ready(
    candidate: skir.PublicationCandidateId(value: "reviewed"),
    baseline: skir.PublicationBaseline.wrapSelected(_selected),
    changes: _delta(large: large),
    notices: notices,
  ),
);

final _problem = skir.PublicationDiagnosticDetails(
  evidence: null,
  id: skir.DiagnosticId(value: "missing_target"),
  origin: skir.RuleOrigin.defaultInstance,
  code: "missing_target",
  message: "Dialogue points to a missing page",
  primary: skir.ValueLocation(
    resource: skir.ResourceId(value: "page:arrival"),
    path: skir.ValuePath(segments: const []),
  ),
  related: const [],
);

skir.PublicationNotice _warning(int index) =>
    skir.PublicationNotice.wrapWarning(
      skir.PublicationDiagnosticDetails(
        evidence: null,
        id: skir.DiagnosticId(value: "notice_$index"),
        origin: skir.RuleOrigin.defaultInstance,
        code: "dialogue_review",
        message: "Review dialogue ${index + 1} before release",
        primary: _problem.primary,
        related: const [],
      ),
    );
