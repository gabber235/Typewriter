import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

@RoutePage()
class RealmPage extends HookConsumerWidget {
  const RealmPage({@PathParam("realmId") required this.realmId, super.key});

  final String realmId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizationId = ref.watch(organizationIdProvider);
    final selectedRealmId = ref.watch(realmIdProvider);
    if (organizationId != null &&
        selectedRealmId != null &&
        selectedRealmId.id == realmId) {
      ref.watch(authoringSessionProvider(organizationId, selectedRealmId));
    }
    return AutoRouter();
  }
}
