import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/features/organizations/features/members/application/application.dart";
import "package:typewriter_panel/features/organizations/features/members/application/members.dart";
import "package:typewriter_panel/shared/ui/components/popups.dart";

class MemberRowActions extends HookConsumerWidget {
  const MemberRowActions({required this.member, super.key});

  final OrganizationMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isRemoving = useState(false);

    if (isRemoving.value) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: IconButton(
        icon: Icon(
          Icons.person_remove_outlined,
          size: 20,
          color: theme.colorScheme.error,
        ),
        onPressed: () => _confirmRemoveMember(context, ref, isRemoving),
        tooltip: "Remove member",
      ),
    );
  }

  Future<void> _confirmRemoveMember(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isRemoving,
  ) async {
    await showConfirmationDialogue(
      context: context,
      title: "Remove ${member.name}?",
      content:
          "Are you sure you want to remove this member from the organization?",
      confirmText: "Remove",
      confirmIcon: Fa6Solid.user_minus,
      onConfirm: () async {
        isRemoving.value = true;
        await ref
            .read(organizationMembersProvider.notifier)
            .removeMember(member.userId);
      },
    );
  }
}
