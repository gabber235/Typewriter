import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Domain comparison content. Actions and retention belong to the shared owner.
final class RealmEditingReview extends HookWidget {
  const RealmEditingReview({
    required this.workspace,
    required this.id,
    super.key,
  });
  final RealmEditing workspace;
  final EditGroupId id;
  @override
  Widget build(BuildContext context) {
    useListenable(workspace);
    final group = workspace.state.groups[id];
    if (group == null) return const Text("Changes are settled");
    final phase = group.phase;
    final proposed = phase is EditGroupResourceMissing<AuthoringDocument>
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
    return SizedBox(
      width: 700,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final resource
                in group.resources.whereType<skir.ResourceId>()) ...[
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text("Before changes"),
                        value(group.original, resource, "Created locally"),
                      ],
                    ),
                  ),
                  SizedBox(width: context.spacing.space4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text("Working"),
                        value(proposed, resource, "Removed locally"),
                      ],
                    ),
                  ),
                  SizedBox(width: context.spacing.space4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text("Saved"),
                        value(confirmed, resource, "Absent from the Realm"),
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
    );
  }
}
