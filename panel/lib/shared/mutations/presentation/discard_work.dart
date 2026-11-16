import "package:typewriter_panel/typewriter_panel.dart";

/// Discard holds: it throws away unsaved work. A false discard means the
/// work changed under the hold; the Discard button jams and says so.
/// Local work entries are not AnimatedRows, so the button owns the refusal.
ActionShortcut discardWork({
  required WorkEntryId entry,
  required String label,
  required bool Function(WorkEntryId entry) discard,
}) {
  return ActionShortcut(
    id: "discard_work_$entry",
    label: "Discard",
    description: "Throw away this unsaved work",
    activators: const [],
    priority: 1,
    show: false,
    run: ActionRun.hold(
      HoldPlan<WorkEntryId>(
        // Only the user's own draft is lost.
        weight: HoldWeight.light,
        targets: (_) => {entry},
        verb: "Discard",
        doneWord: "Discarded",
        outcome: (_) => "Discard $label? Your unsaved changes are lost.",
        each: (_, entry) {
          if (!discard(entry)) {
            throw const HoldRefused(
              "This work changed and can no longer be discarded.",
            );
          }
        },
      ),
    ),
  );
}
