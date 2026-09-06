import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class PageDiagnosticsBanner extends ConsumerWidget {
  const PageDiagnosticsBanner({required this.pageId, super.key});

  final String pageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    if (organizationId == null || realmId == null) {
      return const SizedBox.shrink();
    }
    final health = ref.watch(
      pageDocumentHealthProvider(
        organizationId,
        realmId,
        recordId("page:$pageId"),
      ),
    );
    if (health == null ||
        (!health.compileBlocked && health.diagnostics.isEmpty)) {
      return const SizedBox.shrink();
    }
    final message = health.diagnostics.isEmpty
        ? "Compilation is blocked. The engine keeps the last valid version."
        : health.diagnostics.join("\n");
    final theme = Theme.of(context);
    return SafeArea(
      minimum: EdgeInsets.all(context.spacing.space3),
      child: Material(
        color: theme.colorScheme.errorContainer,
        borderRadius: context.shapes.mediumBorderRadius,
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.spacing.space3,
            vertical: context.spacing.space2,
          ),
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
        ),
      ),
    );
  }
}
