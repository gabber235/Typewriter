import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The one Decline command: the card key, and the operation the inspector
/// and the context menu offer, all build it.
///
/// Every target is declined in one change or none is. Their rows, from
/// [rows] or else [rowsOf] when the hold starts, are sending while it runs,
/// and a refusal stays on each of them.
ActionShortcut joinRequestDecline({
  required String id,
  required String label,
  required Set<skir.RecordId> Function(WidgetRef ref) targets,
  required String? Function(WidgetRef ref, skir.RecordId request) nameOf,
  HoldRows? rows,
  HoldRows? Function(WidgetRef ref)? rowsOf,
  int priority = 1,
}) {
  // They must ask again to join, so the hold is heavy.
  return membershipHold(
    id: id,
    label: label,
    description: "Decline so they must ask again",
    targets: targets,
    nameOf: nameOf,
    rows: rows,
    rowsOf: rowsOf,
    priority: priority,
    verb: "Decline",
    doneWord: "Declined",
    outcomeOne: (name) =>
        "Decline ${name ?? "this request"}? They must ask again to join.",
    outcomeMany: (count) =>
        "Decline $count requests? They must ask again to join.",
    work: (ref, requests) async {
      await ref.executeMembership(
        ref.membershipCommands.decline(requests),
        (response) => response.requireAccepted(),
      );
      ref.read(joinRequestGrantsProvider.notifier).forget(requests);
    },
  );
}
