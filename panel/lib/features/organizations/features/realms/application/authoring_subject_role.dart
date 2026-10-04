import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/catalog.dart"
    as catalog_wire;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/expression.dart"
    as expression;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:typewriter_panel/typewriter_panel.dart";

final class AuthoringSubjectRole extends ConsumerWidget {
  const AuthoringSubjectRole({
    required this.resourceId,
    required this.role,
    super.key,
  });

  final types.ResourceId resourceId;
  final catalog_wire.PresentationRole role;

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
      budget: expression.EvaluationBudget(
        maxSteps: 10000,
        maxCollectionItems: 10000,
      ),
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
