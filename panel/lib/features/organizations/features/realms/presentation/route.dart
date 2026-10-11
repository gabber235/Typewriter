import "package:typewriter_panel/typewriter_panel.dart";

/// Nested route that activates the authoring session for the selected realm.
///
/// Route identity comes from [realmId]. The session is watched only when the
/// typed organization and realm providers agree with that route, preventing a
/// stale provider value from opening authoring state for another destination.
@RoutePage()
class RealmPage extends HookConsumerWidget {
  const RealmPage({@PathParam("realmId") required this.realmId, super.key});

  final String realmId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizationId = ref.watch(organizationIdProvider);
    final selectedRealmId = ref.watch(realmIdProvider);
    AuthoringWorkspace? workspace;
    AuthoringScope? scope;
    if (organizationId != null &&
        selectedRealmId != null &&
        selectedRealmId.id == realmId) {
      scope = AuthoringScope(
        organizationId: organizationId,
        realmId: selectedRealmId,
      );
      workspace = ref.watch(
        authoringWorkspaceProvider(
          AuthoringScope(
            organizationId: organizationId,
            realmId: selectedRealmId,
          ),
        ),
      );
    }
    return Column(
      children: [
        if (workspace != null && scope != null)
          RealmWorkToolbar(workspace: workspace, scope: scope),
        const Expanded(child: AutoRouter()),
      ],
    );
  }
}
