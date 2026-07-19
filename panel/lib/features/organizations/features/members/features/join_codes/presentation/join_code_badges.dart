import "package:flutter/material.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/application/application.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/application/join_codes.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/presentation/type_badge.dart";
import "package:typewriter_panel/shared/ui/components/surface.dart";

class JoinCodeTypeBadges extends StatelessWidget {
  const JoinCodeTypeBadges({required this.code, super.key});

  final OrganizationJoinCode code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      spacing: 6,
      children: [
        if (code.singleUse)
          TypeBadge(
            icon: Icons.looks_one_rounded,
            label: "Single-use",
            color: theme.colorScheme.tertiary,
            backgroundColor: theme.colorScheme.tertiaryContainer,
          )
        else
          TypeBadge(
            icon: Icons.all_inclusive_rounded,
            label: "Multi-use",
            color: theme.colorScheme.onSurfaceVariant,
            backgroundColor: Surface.colorOf(context),
          ),
        if (code.autoAccept.roleIds.isNotEmpty)
          TypeBadge(
            icon: Icons.flash_on_rounded,
            label: "Auto-accept",
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.primaryContainer,
          ),
      ],
    );
  }
}
