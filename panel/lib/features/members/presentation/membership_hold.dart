import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// A heavy hold on Delete that sends one all or nothing membership change
/// over its targets: the shape Remove member, Revoke join code and Decline
/// share.
///
/// [outcomeOne] names the one target by [nameOf], read with the targets on
/// every preview and start, or gets null when it has no name;
/// [outcomeMany] counts several. When the backend refuses some targets,
/// every other one says it was held back, by its name or else as this
/// [noun]. The target rows, on the surface showing the selection when the
/// hold starts, are sending while [work] runs, and a refusal stays on each
/// of them.
ActionShortcut membershipHold({
  required String id,
  required String label,
  required String description,
  required Set<skir.RecordId> Function(WidgetRef ref) targets,
  required String verb,
  required String doneWord,
  required String noun,
  required String Function(String? name) outcomeOne,
  required String Function(int count) outcomeMany,
  required Future<void> Function(WidgetRef ref, Set<skir.RecordId> targets)
  work,
  String? Function(WidgetRef ref, skir.RecordId target)? nameOf,
  int priority = 1,
}) {
  String? named;
  return ActionShortcut.intent(
    id: id,
    label: label,
    description: description,
    intent: DeleteIntent,
    priority: priority,
    run: ActionRun.hold(
      HoldPlan<skir.RecordId>.all(
        weight: HoldWeight.heavy,
        rows: (ref) => ref.selectionRows,
        targets: (ref) {
          final picked = targets(ref);
          named = picked.length == 1 ? nameOf?.call(ref, picked.single) : null;
          return picked;
        },
        verb: verb,
        doneWord: doneWord,
        outcome: (targets) => targets.length == 1
            ? outcomeOne(named)
            : outcomeMany(targets.length),
        work: work,
        heldBack: (ref, target) =>
            "${nameOf?.call(ref, target) ?? "This $noun"} was not "
            "${doneWord.toLowerCase()}, because another $noun in this change "
            "was refused. Nothing was saved.",
      ),
    ),
  );
}
