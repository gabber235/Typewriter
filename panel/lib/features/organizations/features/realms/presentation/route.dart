import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

@RoutePage()
class RealmPage extends HookConsumerWidget {
  const RealmPage({@PathParam("realmId") required this.realmId, super.key});

  final String realmId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AutoRouter();
  }
}
