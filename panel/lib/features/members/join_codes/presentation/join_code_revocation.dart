import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The one Revoke command, which the operation the inspector, the context
/// menu and its key offer builds.
///
/// Every target is revoked in one change or none is. Their rows on the
/// surface showing them are sending while it runs, and a refusal
/// stays on each of them.
ActionShortcut joinCodeRevocation({
  required String id,
  required String label,
  required Set<skir.RecordId> Function(WidgetRef ref) targets,
  int priority = 1,
}) {
  // Whoever holds the code needs a new one, so the hold is heavy.
  return membershipHold(
    id: id,
    label: label,
    description: "Revoke so it stops working",
    targets: targets,
    priority: priority,
    verb: "Revoke",
    doneWord: "Revoked",
    noun: "join code",
    outcomeOne: (_) => "Revoke this join code? Nobody new can join with it.",
    outcomeMany: (count) =>
        "Revoke $count join codes? Nobody new can join with them.",
    work: (ref, codes) => ref.executeMembership(
      ref.membershipCommands.revoke(codes),
      (response) => response.requireAccepted(),
    ),
  );
}
