import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The one Revoke command: row key, row icon, card key and button, bulk key
/// and button all build it.
///
/// Every code is tried; each refusal shows under its row in [rows].
ActionShortcut joinCodeRevocation({
  required String id,
  required String label,
  required Set<skir.RecordId> Function() targets,
  required AnimatedRows<Object?> rows,
  int priority = 1,
}) {
  return ActionShortcut.intent(
    id: id,
    label: label,
    description: "Revoke so it stops working",
    intent: DeleteIntent,
    priority: priority,
    run: ActionRun.hold(
      HoldPlan<skir.RecordId>(
        rows: rows,
        targets: (_) => targets(),
        verb: "Revoke",
        outcome: (targets) => targets.length == 1
            ? "Revoke this join code? Nobody new can join with it."
            : "Revoke ${targets.length} join codes? "
                  "Nobody new can join with them.",
        each: (ref, code) => ref.executeMembership(
          ref.membershipCommands.revoke(code),
          (response) => response.requireAccepted(),
        ),
      ),
    ),
  );
}
