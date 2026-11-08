import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The one Remove member command: row key, row icon, card key and button,
/// bulk key and button all build it.
///
/// [rows] are the members rows MembersTab owns: each member's row is
/// sending while its remove runs, and a refusal stays on its row. Removed
/// members leave the live list, and refused members stay selected.
ActionShortcut memberRemoval({
  required String id,
  required String label,
  required Set<skir.RecordId> Function() targets,
  required AnimatedRows<Object?> rows,
  required String? Function(skir.RecordId member) nameOf,
  int priority = 1,
}) {
  return ActionShortcut.intent(
    id: id,
    label: label,
    description: "Remove from the organization",
    intent: DeleteIntent,
    priority: priority,
    run: ActionRun.hold(
      HoldPlan<skir.RecordId>(
        rows: rows,
        targets: (_) => targets(),
        verb: "Remove",
        outcome: (targets) => targets.length == 1
            ? "Remove ${nameOf(targets.single) ?? "this member"}? "
                  "They lose access straight away."
            : "Remove ${targets.length} members? "
                  "They lose access straight away.",
        each: (ref, member) => ref.executeMembership(
          ref.membershipCommands.remove(member),
          (response) => response.requireAccepted(),
        ),
      ),
    ),
  );
}
