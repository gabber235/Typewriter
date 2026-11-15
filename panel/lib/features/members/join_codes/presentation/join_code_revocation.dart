import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The one Revoke command: the row key and icon, and the operation the
/// inspector and the context menu offer, all build it.
///
/// Every target is revoked in one change or none is. Their rows, from
/// [rows] or else [rowsOf] when the hold starts, are sending while it runs,
/// and a refusal stays on each of them.
ActionShortcut joinCodeRevocation({
  required String id,
  required String label,
  required Set<skir.RecordId> Function(WidgetRef ref) targets,
  HoldRows? rows,
  HoldRows? Function(WidgetRef ref)? rowsOf,
  int priority = 1,
}) {
  // Whoever holds the code needs a new one, so the hold is heavy.
  return membershipHold(
    id: id,
    label: label,
    description: "Revoke so it stops working",
    targets: targets,
    rows: rows,
    rowsOf: rowsOf,
    priority: priority,
    verb: "Revoke",
    doneWord: "Revoked",
    outcomeOne: (_) => "Revoke this join code? Nobody new can join with it.",
    outcomeMany: (count) =>
        "Revoke $count join codes? Nobody new can join with them.",
    work: (ref, codes) => ref.executeMembership(
      ref.membershipCommands.revoke(codes),
      (response) => response.requireAccepted(),
    ),
  );
}
