import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

final _driver = WorkDriverId(domain: "members", scope: "acme");

WorkEntryState _draft(
  String label, {
  bool saving = false,
  bool needsAttention = false,
  bool needsInput = false,
}) => WorkEntryState(
  id: WorkEntryId(driver: _driver, identity: label),
  label: label,
  phase: switch ((saving, needsAttention, needsInput)) {
    (true, _, _) => "Saving",
    (_, true, _) => "The server refused the change",
    (_, _, true) => "Choose a role first",
    _ => "Unsaved",
  },
  hasWork: true,
  canSave: !saving,
  canDiscard: !saving,
  canRetry: needsAttention,
  saving: saving,
  needsAttention: needsAttention,
  needsInput: needsInput,
);

LocalWorkSubmissionState _submission(
  String label,
  LocalWorkSubmissionPhase phase,
) => LocalWorkSubmissionState(id: label, label: label, phase: phase);

/// The save activity outside a Realm in every phase it resolves to.
final _phases = <String, LocalWorkState>{
  "Idle": const LocalWorkState(),
  "Pending": LocalWorkState(
    submissions: [
      _submission(
        "Generate join code",
        const LocalWorkSubmissionPhase.prepared(),
      ),
    ],
  ),
  "Saving": LocalWorkState(
    submissions: [
      _submission(
        "Generate join code",
        const LocalWorkSubmissionPhase.active(),
      ),
    ],
  ),
  "Saving with attention": LocalWorkState(
    submissions: [
      _submission(
        "Generate join code",
        const LocalWorkSubmissionPhase.active(),
      ),
      _submission(
        "Remove member Grace",
        const LocalWorkSubmissionPhase.settled(
          LocalWorkKnownOutcome.rejected("Grace owns this organization"),
          LocalWorkIntegration.applied(),
        ),
      ),
    ],
  ),
  "Needs attention": LocalWorkState(
    entries: {
      for (final entry in [_draft("Roles of Grace", needsAttention: true)])
        entry.id: entry,
    },
  ),
  "Needs input": LocalWorkState(
    entries: {
      for (final entry in [_draft("Approve request", needsInput: true)])
        entry.id: entry,
    },
  ),
  "Drafts": LocalWorkState(
    entries: {
      for (final entry in [_draft("Roles of Grace"), _draft("Service name")])
        entry.id: entry,
    },
  ),
  "Saved": LocalWorkState(
    submissions: [
      _submission(
        "Generate join code",
        const LocalWorkSubmissionPhase.settled(
          LocalWorkKnownOutcome.confirmed(),
          LocalWorkIntegration.applied(),
        ),
      ),
    ],
  ),
};

/// The [MutationActivityView] the app bar shows for work outside a Realm
/// (members, join codes, services), in each phase; it opens its details as a
/// popup on desktop and as a sheet in a compact window.
@widgetbook.UseCase(name: "Default", type: MutationActivityView)
Widget mutationActivityUseCase(BuildContext context) {
  final phase = context.knobs.object.dropdown(
    label: "Phase",
    options: _phases.keys.toList(),
    initialOption: "Needs attention",
  );
  return Story(
    [
      signedIn(ada, organization: acme),
      ...context.knobs.traits("Window", {
        "Desktop": const [],
        "Compact": const [compact],
      }),
    ],
    at: PanelLocation.component(
      Consumer(
        builder: (context, ref, _) {
          return MutationActivityView(
            state: _phases[phase]!,
            controller: ref.read(localWorkControllerProvider),
          );
        },
      ),
    ),
  );
}
