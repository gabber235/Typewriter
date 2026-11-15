import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The one Decline command, which the operation the inspector, the context
/// menu and its key offer builds.
///
/// Every target is declined in one change or none is. Their rows on the
/// surface showing them are sending while it runs, and a refusal
/// stays on each of them.
ActionShortcut joinRequestDecline({
  required String id,
  required String label,
  required Set<skir.RecordId> Function(WidgetRef ref) targets,
  required String? Function(WidgetRef ref, skir.RecordId request) nameOf,
  int priority = 1,
}) {
  // They must ask again to join, so the hold is heavy.
  return membershipHold(
    id: id,
    label: label,
    description: "Decline so they must ask again",
    targets: targets,
    nameOf: nameOf,
    priority: priority,
    verb: "Decline",
    doneWord: "Declined",
    noun: "request",
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
