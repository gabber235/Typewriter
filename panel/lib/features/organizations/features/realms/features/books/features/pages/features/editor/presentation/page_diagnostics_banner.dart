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
    return SafeArea(
      minimum: const EdgeInsets.all(12),
      child: Material(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ),
      ),
    );
  }
}
