import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The one Decline command: card key and button, bulk key and button.
///
/// Every request is tried; each refusal shows under its row in [rows].
ActionShortcut joinRequestDecline({
  required String id,
  required String label,
  required Set<skir.RecordId> Function() targets,
  required AnimatedRows<Object?> rows,
  required String? Function(skir.RecordId request) nameOf,
  int priority = 1,
}) {
  return ActionShortcut.intent(
    id: id,
    label: label,
    description: "Decline so they must ask again",
    intent: DeleteIntent,
    priority: priority,
    run: ActionRun.hold(
      HoldPlan<skir.RecordId>(
        // They must ask again to join.
        weight: HoldWeight.heavy,
        rows: rows,
        targets: (_) => targets(),
        verb: "Decline",
        outcome: (targets) => targets.length == 1
            ? "Decline ${nameOf(targets.single) ?? "this request"}? "
                  "They must ask again to join."
            : "Decline ${targets.length} requests? "
                  "They must ask again to join.",
        each: (ref, request) => ref.executeMembership(
          ref.membershipCommands.decline(request),
          (response) => response.requireAccepted(),
        ),
      ),
    ),
  );
}
