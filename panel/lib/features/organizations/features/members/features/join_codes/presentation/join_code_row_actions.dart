import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class JoinCodeRowActions extends HookConsumerWidget {
  const JoinCodeRowActions({required this.code, super.key});

  final OrganizationJoinCode code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isRevoking = useState(false);

    if (isRevoking.value) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.spacing.space2),
      child: IconButton(
        icon: Icon(Icons.link_off, size: 20, color: theme.colorScheme.error),
        onPressed: () => _confirmRevokeCode(context, ref, isRevoking),
        tooltip: "Revoke join code",
      ),
    );
  }

  Future<void> _confirmRevokeCode(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isRevoking,
  ) async {
    await showConfirmationDialogue(
      context: context,
      title: "Revoke this join code?",
      content:
          "Are you sure you want to revoke this join code? It will no longer work for new members.",
      confirmText: "Revoke",
      confirmIcon: Fa6Solid.link_slash,
      onConfirm: () async {
        isRevoking.value = true;
        await ref
            .read(organizationJoinCodesProvider.notifier)
            .revokeCode(code.code);
      },
    );
  }
}
