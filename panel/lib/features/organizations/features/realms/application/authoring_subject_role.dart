import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

final class AuthoringSubjectRole extends ConsumerWidget {
  const AuthoringSubjectRole({
    required this.resourceId,
    required this.role,
    super.key,
  });

  final skir.ResourceId resourceId;
  final skir.PresentationRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    if (organizationId == null || realmId == null) {
      return const _UnavailableRole();
    }
    final state = ref.watch(authoringSessionProvider(organizationId, realmId));
    final draft = state.draft;
    final catalog = state.catalog;
    if (state.failure != null || draft == null || catalog == null) {
      return state.snapshot == null
          ? ShimmerBox.rectangle(width: double.infinity, height: 20)
          : const _UnavailableRole();
    }
    return AuthoredResourceEditor(
      resource: resourceId,
      draft: draft,
      catalog: catalog,
      role: role,
      budget: skir.EvaluationBudget(maxSteps: 10000, maxCollectionItems: 10000),
      enabled: false,
    );
  }
}

final class _UnavailableRole extends StatelessWidget {
  const _UnavailableRole();

  @override
  Widget build(BuildContext context) => const Tooltip(
    message: "Resource presentation is unavailable",
    child: Icon(Icons.warning_rounded, size: 14),
  );
}
