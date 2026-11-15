import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The one Remove member command: the row key and icon, and the operation
/// the inspector and the context menu offer, all build it.
///
/// Every target leaves in one change or none does. Their rows, from [rows]
/// or else [rowsOf] when the hold starts, are sending while it runs, and a
/// refusal stays on each of them; removed members leave the live list.
ActionShortcut memberRemoval({
  required String id,
  required String label,
  required Set<skir.RecordId> Function(WidgetRef ref) targets,
  required String? Function(WidgetRef ref, skir.RecordId member) nameOf,
  HoldRows? rows,
  HoldRows? Function(WidgetRef ref)? rowsOf,
  int priority = 1,
}) {
  // The member must ask to join again, so the hold is heavy.
  return membershipHold(
    id: id,
    label: label,
    description: "Remove from the organization",
    targets: targets,
    nameOf: nameOf,
    rows: rows,
    rowsOf: rowsOf,
    priority: priority,
    verb: "Remove",
    doneWord: "Removed",
    noun: "member",
    outcomeOne: (name) =>
        "Remove ${name ?? "this member"}? They lose access straight away.",
    outcomeMany: (count) =>
        "Remove $count members? They lose access straight away.",
    work: (ref, members) => ref.executeMembership(
      ref.membershipCommands.remove(members),
      (response) => response.requireAccepted(),
    ),
  );
}
