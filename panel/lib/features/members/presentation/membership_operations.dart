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

/// The selected items of type [T], in selection order.
extension on WidgetRef {
  List<T> selectedOf<T extends Selectable>() =>
      (read(selectedProvider).value ?? const <Selectable>[])
          .whereType<T>()
          .toList();
}

/// Removes the selected members with a hold, all or none.
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
  bool canExecuteOn(List<Selectable> selection) =>
      selection.isNotEmpty &&
      selection.every((item) => item is MemberSelectable);

  @override
  ActionShortcut get shortcut => memberRemoval(
    id: "operation_remove_members",
    label: "Remove member",
    targets: (ref) => {
      for (final member in ref.selectedOf<MemberSelectable>())
        member.member.userId,
    },
    nameOf: (ref, id) => ref
        .selectedOf<MemberSelectable>()
        .firstWhereOrNull((member) => member.member.userId == id)
        ?.name,
    rowsOf: (ref) => ref.read(membershipRowsProvider)[MembershipList.members],
    priority: 10,
  );

  @override
  FutureOr<void> executeOn(WidgetRef ref) =>
      throw StateError("Remove runs only through its hold.");

  @override
  ActionRun? get run => shortcut.run;

  @override
  MenuItem menuItem(WidgetRef ref) {
    return MenuItem.command(
      command: shortcut,
      icon: const Icon(Icons.person_remove_outlined),
    );
  }

  @override
  Widget inspectorButton(
    List<Selectable> selection, {
    required OperationEmphasis emphasis,
  }) {
    return CommandButton(
      command: shortcut,
      face: emphasis.face,
      icon: const Icon(Icons.person_remove_outlined, size: 16),
      label: selection.length > 1 ? "Remove ${selection.length}" : "Remove",
    );
  }
}

/// Revokes the selected join codes with a hold, all or none.
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
  bool canExecuteOn(List<Selectable> selection) =>
      selection.isNotEmpty &&
      selection.every((item) => item is JoinCodeSelectable);

  @override
  ActionShortcut get shortcut => joinCodeRevocation(
    id: "operation_revoke_join_codes",
    label: "Revoke join code",
    targets: (ref) => {
      for (final code in ref.selectedOf<JoinCodeSelectable>()) code.code.code,
    },
    rowsOf: (ref) => ref.read(membershipRowsProvider)[MembershipList.joinCodes],
    priority: 10,
  );

  @override
  FutureOr<void> executeOn(WidgetRef ref) =>
      throw StateError("Revoke runs only through its hold.");

  @override
  ActionRun? get run => shortcut.run;

  @override
  MenuItem menuItem(WidgetRef ref) {
    return MenuItem.command(
      command: shortcut,
      icon: const Icon(Icons.link_off),
    );
  }

  @override
  Widget inspectorButton(
    List<Selectable> selection, {
    required OperationEmphasis emphasis,
  }) {
    return CommandButton(
      command: shortcut,
      face: emphasis.face,
      icon: const Icon(Icons.link_off, size: 16),
      label: selection.length > 1 ? "Revoke ${selection.length}" : "Revoke",
    );
  }
}

/// Declines the selected join requests with a hold, all or none.
final class DeclineJoinRequestsOperation extends ShortcutableOperation {
  const DeclineJoinRequestsOperation();

  @override
  String get name => "Decline";

  @override
  String get description => "Decline the selected join requests";

  @override
  OperationSection get section => OperationSection.destructive;

  @override
  bool canExecuteOn(List<Selectable> selection) =>
      selection.isNotEmpty &&
      selection.every((item) => item is JoinRequestSelectable);

  @override
  ActionShortcut get shortcut => joinRequestDecline(
    id: "operation_decline_join_requests",
    label: "Decline",
    targets: (ref) => {
      for (final request in ref.selectedOf<JoinRequestSelectable>())
        request.request.requestId,
    },
    nameOf: (ref, id) => ref
        .selectedOf<JoinRequestSelectable>()
        .firstWhereOrNull((request) => request.request.requestId == id)
        ?.name,
    rowsOf: (ref) =>
        ref.read(membershipRowsProvider)[MembershipList.joinRequests],
    priority: 10,
  );

  @override
  FutureOr<void> executeOn(WidgetRef ref) =>
      throw StateError("Decline runs only through its hold.");

  @override
  ActionRun? get run => shortcut.run;

  @override
  MenuItem menuItem(WidgetRef ref) {
    return MenuItem.command(command: shortcut, icon: const Icon(Icons.close));
  }

  @override
  Widget inspectorButton(
    List<Selectable> selection, {
    required OperationEmphasis emphasis,
  }) {
    return CommandButton(
      command: shortcut,
      face: emphasis.face,
      icon: const Icon(Icons.close, size: 16),
      label: selection.length > 1 ? "Decline ${selection.length}" : "Decline",
    );
  }
}

/// Accepts the selected join requests, each with the roles chosen for it
/// in the inspector, all or none. It is offered once every selected request
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
  bool canExecuteOn(List<Selectable> selection) =>
      selection.isNotEmpty &&
      selection.every(
        (item) => item is JoinRequestSelectable && item.grant.isNotEmpty,
      );

  @override
  Future<void> executeOn(WidgetRef ref) async {
    final requests = ref.selectedOf<JoinRequestSelectable>();
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
  MenuItem menuItem(WidgetRef ref) {
    return MenuItem.command(command: shortcut, icon: const Icon(Icons.check));
  }

  @override
  Widget inspectorButton(
    List<Selectable> selection, {
    required OperationEmphasis emphasis,
  }) {
    return CommandButton(
      command: shortcut,
      face: emphasis.face,
      icon: const Icon(Icons.check, size: 16),
      label: selection.length > 1 ? "Accept ${selection.length}" : "Accept",
      busyLabel: "Accepting",
    );
  }
}
