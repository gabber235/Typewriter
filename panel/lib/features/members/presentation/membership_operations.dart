import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The operations on members, join codes and join requests, offered for the
/// selection in the inspector, the context menu and by key.
const membershipSelectionOperations = <SelectionOperation>[
  AcceptJoinRequestsOperation(),
  RemoveMembersOperation(),
  RevokeJoinCodesOperation(),
  DeclineJoinRequestsOperation(),
];

/// The targets of type [T], in target order.
extension on OperationTargets {
  List<T> of<T extends Selectable>(WidgetRef ref) =>
      this(ref).whereType<T>().toList();
}

/// Removes the targeted members with a hold, all or none.
final class RemoveMembersOperation extends ShortcutableOperation {
  const RemoveMembersOperation();

  @override
  String get name => "Remove member";

  @override
  String get description => "Remove the selected members";

  @override
  OperationSection get section => OperationSection.destructive;

  @override
  OperationEmphasis get emphasis => OperationEmphasis.filled;

  @override
  bool canExecuteOn(List<Selectable> targets) =>
      targets.isNotEmpty && targets.every((item) => item is MemberSelectable);

  @override
  ActionShortcut commandOn(OperationTargets targets) => memberRemoval(
    id: "operation_remove_members",
    label: "Remove member",
    targets: (ref) => {
      for (final member in targets.of<MemberSelectable>(ref))
        member.member.userId,
    },
    nameOf: (ref, id) => targets
        .of<MemberSelectable>(ref)
        .firstWhereOrNull((member) => member.member.userId == id)
        ?.name,
    priority: 10,
  );

  @override
  ActionRun? run(OperationTargets targets) => commandOn(targets).run;

  @override
  MenuItem menuItem(WidgetRef ref, OperationTargets targets) {
    return MenuItem.command(
      command: commandOn(targets),
      icon: const Icon(Icons.person_remove_outlined),
    );
  }

  @override
  Widget inspectorButton(
    List<Selectable> selection, {
    required OperationEmphasis emphasis,
  }) {
    return CommandButton(
      command: commandOn(fixedTargets(selection)),
      face: emphasis.face,
      icon: const Icon(Icons.person_remove_outlined, size: 16),
      label: selection.length > 1 ? "Remove ${selection.length}" : "Remove",
    );
  }
}

/// Revokes the targeted join codes with a hold, all or none.
final class RevokeJoinCodesOperation extends ShortcutableOperation {
  const RevokeJoinCodesOperation();

  @override
  String get name => "Revoke join code";

  @override
  String get description => "Revoke the selected join codes";

  @override
  OperationSection get section => OperationSection.destructive;

  @override
  OperationEmphasis get emphasis => OperationEmphasis.filled;

  @override
  bool canExecuteOn(List<Selectable> targets) =>
      targets.isNotEmpty && targets.every((item) => item is JoinCodeSelectable);

  @override
  ActionShortcut commandOn(OperationTargets targets) => joinCodeRevocation(
    id: "operation_revoke_join_codes",
    label: "Revoke join code",
    targets: (ref) => {
      for (final code in targets.of<JoinCodeSelectable>(ref)) code.code.code,
    },
    priority: 10,
  );

  @override
  ActionRun? run(OperationTargets targets) => commandOn(targets).run;

  @override
  MenuItem menuItem(WidgetRef ref, OperationTargets targets) {
    return MenuItem.command(
      command: commandOn(targets),
      icon: const Icon(Icons.link_off),
    );
  }

  @override
  Widget inspectorButton(
    List<Selectable> selection, {
    required OperationEmphasis emphasis,
  }) {
    return CommandButton(
      command: commandOn(fixedTargets(selection)),
      face: emphasis.face,
      icon: const Icon(Icons.link_off, size: 16),
      label: selection.length > 1 ? "Revoke ${selection.length}" : "Revoke",
    );
  }
}

/// Declines the targeted join requests with a hold, all or none.
final class DeclineJoinRequestsOperation extends ShortcutableOperation {
  const DeclineJoinRequestsOperation();

  @override
  String get name => "Decline";

  @override
  String get description => "Decline the selected join requests";

  @override
  OperationSection get section => OperationSection.destructive;

  @override
  bool canExecuteOn(List<Selectable> targets) =>
      targets.isNotEmpty &&
      targets.every((item) => item is JoinRequestSelectable);

  @override
  ActionShortcut commandOn(OperationTargets targets) => joinRequestDecline(
    id: "operation_decline_join_requests",
    label: "Decline",
    targets: (ref) => {
      for (final request in targets.of<JoinRequestSelectable>(ref))
        request.request.requestId,
    },
    nameOf: (ref, id) => targets
        .of<JoinRequestSelectable>(ref)
        .firstWhereOrNull((request) => request.request.requestId == id)
        ?.name,
    priority: 10,
  );

  @override
  ActionRun? run(OperationTargets targets) => commandOn(targets).run;

  @override
  MenuItem menuItem(WidgetRef ref, OperationTargets targets) {
    return MenuItem.command(
      command: commandOn(targets),
      icon: const Icon(Icons.close),
    );
  }

  @override
  Widget inspectorButton(
    List<Selectable> selection, {
    required OperationEmphasis emphasis,
  }) {
    return CommandButton(
      command: commandOn(fixedTargets(selection)),
      face: emphasis.face,
      icon: const Icon(Icons.close, size: 16),
      label: selection.length > 1 ? "Decline ${selection.length}" : "Decline",
    );
  }
}

/// Accepts the targeted join requests, each with the roles chosen for it
/// in the inspector, all or none. It is offered once every targeted request
/// has roles to grant.
final class AcceptJoinRequestsOperation extends ActivatorShortcutOperation {
  const AcceptJoinRequestsOperation();

  @override
  String get name => "Accept";

  @override
  String get description => "Accept the selected join requests";

  @override
  OperationEmphasis get emphasis => OperationEmphasis.filled;

  @override
  List<ShortcutActivator> get activators => const [
    SingleActivator(LogicalKeyboardKey.keyA),
  ];

  @override
  bool canExecuteOn(List<Selectable> targets) =>
      targets.isNotEmpty &&
      targets.every(
        (item) => item is JoinRequestSelectable && item.grant.isNotEmpty,
      );

  @override
  ActionRun run(OperationTargets targets) => pressOn(targets, _accept);

  static Future<void> _accept(WidgetRef ref, List<Selectable> targets) async {
    final requests = targets.whereType<JoinRequestSelectable>().toList();
    if (requests.isEmpty) return;
    final roles = await ref.read(organizationRolesProvider.future);
    final approvals = <skir.RecordId, List<skir.OrganizationRole>>{
      for (final request in requests)
        request.request.requestId: [
          for (final role in roles)
            if (request.grant.contains(role.roleId)) role,
        ],
    };
    await ref.executeMembership(
      ref.membershipCommands.approve(approvals),
      (response) => response.requireAccepted(),
    );
    ref.read(joinRequestGrantsProvider.notifier).forget(approvals.keys);
  }

  @override
  MenuItem menuItem(WidgetRef ref, OperationTargets targets) {
    return MenuItem.command(
      command: commandOn(targets),
      icon: const Icon(Icons.check),
    );
  }

  @override
  Widget inspectorButton(
    List<Selectable> selection, {
    required OperationEmphasis emphasis,
  }) {
    return CommandButton(
      command: commandOn(fixedTargets(selection)),
      face: emphasis.face,
      icon: const Icon(Icons.check, size: 16),
      label: selection.length > 1 ? "Accept ${selection.length}" : "Accept",
      busyLabel: "Accepting",
    );
  }
}
