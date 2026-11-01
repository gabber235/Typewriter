import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Domain comparison content. Actions and retention belong to the shared owner;
/// the review of a conflict is the one the editing keeps for the group.
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
    if (phase != null && phase.needsReview) {
      final reviewed =
          workspace.conflictReview(id) ?? const EditReview.reading();
      final review = reviewed.comparison;
      final reading = reviewed is EditReviewReading;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (reading) const Text("Loading current saved values"),
          if (reviewed is EditReviewFailed)
            const Text(
              "Current saved values are unavailable. Your edits are retained.",
            ),
          if (review != null)
            AuthoringConflictComparison(
              key: ValueKey(review),
              review: review,
              enabled: !reading,
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
            onPressed: () => workspace.refreshConflictReview(id),
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
                resourceAppearanceIn(
                      proposed.catalog,
                      proposed,
                      resource,
                    )?.label ??
                    switch (confirmed) {
                      final confirmed? => resourceAppearanceIn(
                        confirmed.catalog,
                        confirmed,
                        resource,
                      )?.label,
                      null => null,
                    } ??
                    "Removed resource",
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
