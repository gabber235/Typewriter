import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Domain comparison content. Actions and retention belong to the shared owner.
final class RealmEditingReview extends HookWidget {
  const RealmEditingReview({
    required this.workspace,
    required this.id,
    this.onResolved,
    super.key,
  });
  final RealmEditing workspace;
  final EditGroupId id;
  final VoidCallback? onResolved;
  @override
  Widget build(BuildContext context) {
    useListenable(workspace);
    final group = workspace.state.groups[id];
    final phase = group?.phase;
    final refresh = useState(0);
    final needsReview =
        phase is EditGroupConflict ||
        phase is EditGroupResourceMissing ||
        phase is EditGroupRepeatedContention;
    final pending = useMemoized(
      () => needsReview ? workspace.reviewConflict(id) : null,
      [workspace, id, needsReview, refresh.value],
    );
    final reviewed = useFuture(pending);
    if (needsReview) {
      final review = reviewed.data;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (reviewed.connectionState != ConnectionState.done)
            const Text("Loading current saved values"),
          if (reviewed.error != null)
            const Text(
              "Current saved values are unavailable. Your edits are retained.",
            ),
          if (review != null)
            AuthoringConflictComparison(
              key: ValueKey(review),
              review: review,
              enabled:
                  reviewed.connectionState == ConnectionState.done &&
                  reviewed.error == null,
              onKeepMine: review.canKeepMine
                  ? () => workspace.resolveConflict(
                      review,
                      AuthoringConflictChoice.keepMine,
                    )
                  : null,
              onUseSaved: () => workspace.resolveConflict(
                review,
                AuthoringConflictChoice.useSaved,
              ),
              onResolved: onResolved,
            ),
          TextButton(
            onPressed: () => refresh.value++,
            child: const Text("Refresh review"),
          ),
        ],
      );
    }
    if (group == null) return const Text("Changes are settled");
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
                proposed.resource(resource)?.authoredLabel ??
                    confirmed?.resource(resource)?.authoredLabel ??
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
