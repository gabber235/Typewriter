import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

final class AuthoringGroupControls extends StatelessWidget {
  const AuthoringGroupControls({
    required this.workspace,
    required this.group,
    super.key,
  });
  final AuthoringWorkspace workspace;
  final AuthoringGroup group;

  @override
  Widget build(BuildContext context) {
    final phase = group.phase;
    final dependencies = phase is AuthoringGroupAwaitingDependency
        ? phase.groups
              .map(
                (id) => workspace.state.groups[id]?.label ?? "Related changes",
              )
              .join(", ")
        : null;
    return Padding(
      padding: EdgeInsets.all(context.spacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(group.label, style: Theme.of(context).textTheme.titleSmall),
          Text(
            dependencies == null
                ? phase.message
                : "Waiting for: $dependencies. Apply or discard those changes first",
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Wrap(
              children: [
                if (phase is AuthoringGroupDirty &&
                    group.policy == EditorCommitPolicy.applyResource)
                  TextButton(
                    onPressed: () => workspace.save(group.id),
                    child: const Text("Apply"),
                  ),
                if (phase is AuthoringGroupCommittedAwaitingRefresh ||
                    phase is AuthoringGroupUncertain)
                  TextButton(
                    onPressed: workspace.refreshConfirmed,
                    child: const Text("Refresh"),
                  ),
                TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) {
                      final proposed = phase is AuthoringGroupResourceMissing
                          ? phase.proposal
                          : workspace.document;
                      final confirmed = workspace.state.confirmed;
                      Widget value(
                        AuthoringDocument? document,
                        skir.ResourceId resource,
                        String absent,
                      ) => document?.entry(resource) == null
                          ? Text(absent)
                          : AuthoredResourceEditor(
                              resource: resource,
                              document: document!,
                              role: skir.PresentationRole.inspector,
                              budget: skir.EvaluationBudget(
                                maxSteps: 10000,
                                maxCollectionItems: 10000,
                              ),
                            );
                      return AlertDialog(
                        title: Text(group.label),
                        content: SizedBox(
                          width: 700,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final resource in group.resources) ...[
                                  Text(
                                    proposed
                                            .resource(resource)
                                            ?.authoredField("name")
                                            ?.authoredString ??
                                        proposed
                                            .resource(resource)
                                            ?.authoredField("title")
                                            ?.authoredString ??
                                        confirmed
                                            ?.resource(resource)
                                            ?.authoredField("name")
                                            ?.authoredString ??
                                        confirmed
                                            ?.resource(resource)
                                            ?.authoredField("title")
                                            ?.authoredString ??
                                        "Resource",
                                  ),
                                  SizedBox(height: context.spacing.space2),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            const Text("Before changes"),
                                            value(
                                              group.original,
                                              resource,
                                              "Created locally",
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: context.spacing.space4),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            const Text("Working"),
                                            value(
                                              proposed,
                                              resource,
                                              "Removed locally",
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: context.spacing.space4),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            const Text("Saved"),
                                            value(
                                              confirmed,
                                              resource,
                                              "Absent from the Realm",
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: context.spacing.space4),
                                ],
                              ],
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Close"),
                          ),
                        ],
                      );
                    },
                  ),
                  child: const Text("View changes"),
                ),
                if (workspace.canDiscard(group.id))
                  TextButton(
                    onPressed: () => workspace.discard(group.id),
                    child: Text(
                      phase is AuthoringGroupSaving ||
                              phase is AuthoringGroupCommittedAwaitingRefresh ||
                              phase is AuthoringGroupUncertain
                          ? "Discard later edits"
                          : "Discard",
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
