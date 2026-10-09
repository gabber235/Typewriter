import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Publishes saved server content independently of retained local drafts.
final class RealmWorkToolbar extends HookConsumerWidget {
  const RealmWorkToolbar({
    required this.workspace,
    required this.scope,
    super.key,
  });
  final AuthoringWorkspace workspace;
  final AuthoringScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useListenable(workspace);
    final publication = ref.watch(
      realmPublicationProvider(scope.organizationId, scope.realmId),
    );
    final controller = ref.read(
      realmPublicationProvider(scope.organizationId, scope.realmId).notifier,
    );
    final view = publication.value;
    final saved = workspace.state.confirmed;
    final roots = useMemoized(
      () => [
        if (saved != null)
          for (final entry in saved.entries.values)
            if (entry.definition == corePageResourceDefinition)
              skir.CompilationRoot(
                projection: skir.CompilationProjectionId(
                  value: "typewriter.page",
                ),
                resource: entry.id,
              ),
      ],
      [saved],
    );
    final statuses = useFuture(
      useMemoized(() => controller.states(roots), [
        controller,
        roots,
        view?.report?.id,
        view?.report?.state,
      ]),
    );
    return Material(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(child: Text("Saved content publication")),
                TextButton.icon(
                  icon: const Icon(Icons.publish),
                  label: const Text("Publish saved content"),
                  onPressed: view?.canPublish == true
                      ? () async {
                          try {
                            await controller.publish();
                          } on Object catch (error) {
                            if (context.mounted) {
                              showErrorSnackBar(context, error.toString());
                            }
                          }
                        }
                      : null,
                ),
              ],
            ),
            const Text(
              "Pending local changes stay in shared work. Publishing uses saved server values.",
            ),
            if (view?.report case final publication?) ...[
              Text(view!.entry.phase),
              if (publication.findings.isNotEmpty)
                ExpansionTile(
                  title: Text(
                    "Publication findings (${publication.findings.length})",
                  ),
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            for (final finding in publication.findings)
                              ListTile(
                                dense: true,
                                title: Text(finding.message),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
            if (statuses.hasError)
              const Text("Selected publication status is unavailable"),
            if (statuses.data case final values? when values.isNotEmpty)
              ExpansionTile(
                title: Text(
                  "Saved Page publication status (${values.length} Pages)",
                ),
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (final status in values)
                            Text(
                              "${saved?.resource(status.root.resource)?.authoredField("name")?.authoredString ?? saved?.resource(status.root.resource)?.authoredField("title")?.authoredString ?? "Page ${status.root.resource.value}"}: ${status.state.selectedPublicationLabel}",
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

extension CompiledResourceStatusLabel on skir.CompiledResourceState {
  String get selectedPublicationLabel => switch (this) {
    skir.CompiledResourceState_activeWrapper(:final value) =>
      "Last published in ${value.value}",
    skir.CompiledResourceState.notCompiled => "Not in the selected publication",
    _ => "Selected publication status is unknown",
  };
}
