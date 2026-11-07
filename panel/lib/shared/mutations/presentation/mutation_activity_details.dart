part of "mutation_activity_button.dart";

class _ActivityDetails extends StatelessWidget {
  const _ActivityDetails({
    required this.state,
    required this.controller,
    required this.onClose,
  });
  final VoidCallback onClose;
  final LocalWorkState state;
  final LocalWorkCommands controller;

  Future<void> _review(BuildContext context, WorkEntryState resource) async {
    final review = controller.review(resource.id);
    if (review == null) return;
    try {
      await showAdvancedDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(resource.label),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(child: review.content.body),
          ),
          actions: [
            Button(label: "Close", onPressed: () => Navigator.pop(context)),
          ],
        ),
      );
    } finally {
      review.release();
    }
  }

  @override
  Widget build(BuildContext context) {
    final drafts = state.entries.values.toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.spacing.space4,
            context.spacing.space3,
            context.spacing.space2,
            context.spacing.space2,
          ),
          child: Row(
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                color: context.colors.contentSecondary,
                size: 20,
              ),
              SizedBox(width: context.spacing.space2),
              Expanded(
                child: Text(
                  "Save activity",
                  style: context.theme.textTheme.titleMedium,
                ),
              ),
              Button(
                face: ButtonFace.icon,
                icon: const Icon(Icons.close, size: 20),
                label: "Close",
                tooltip: "Close",
                onPressed: onClose,
              ),
            ],
          ),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.fromLTRB(
              context.spacing.space3,
              0,
              context.spacing.space3,
              context.spacing.space3,
            ),
            children: [
              for (final resource in drafts)
                Builder(
                  builder: (context) {
                    final message = resource.phase;
                    final details = resource.details
                        .map((fact) => _ActivityDetail(fact.label, fact.value))
                        .toList();
                    return _ActivityCard(
                      key: ValueKey(("resource", resource.id)),
                      title: resource.label,
                      message: message,
                      details: details,
                      copyText: details.isEmpty
                          ? null
                          : _formatActivityProblemReport(
                              title: resource.label,
                              message: message,
                              details: details,
                            ),
                      phase: MutationActivityPhase.resolve(const [], [
                        resource,
                      ]),
                      actions: [
                        if (resource.canSave)
                          Button(
                            icon: const Icon(Icons.save_outlined, size: 16),
                            label: "Save",
                            onPressed: () => controller.save(resource.id),
                          ),
                        if (resource.canRetry)
                          Button(
                            icon: const Icon(Icons.refresh, size: 16),
                            label: "Retry",
                            onPressed: () => controller.retry(resource.id),
                          ),
                        if (resource.destination ==
                            LocalWorkDestinationState.available)
                          Button(
                            icon: const Icon(Icons.arrow_outward, size: 16),
                            label: "Open work",
                            onPressed: () async {
                              onClose();
                              await controller.open(resource.id);
                            },
                          )
                        else if (resource.canReview &&
                            resource.destination ==
                                LocalWorkDestinationState.unavailable)
                          Button(
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: "Review draft",
                            onPressed: () => _review(context, resource),
                          ),
                        if (resource.canDiscard)
                          Button(
                            label: "Discard",
                            color: context.colors.dangerText,
                            onPressed: resource.canDiscard
                                ? () => controller.discard(resource.id)
                                : null,
                          ),
                      ],
                    );
                  },
                ),
              for (final submission in state.submissions)
                _ActivityCard(
                  key: ValueKey(("submission", submission.id)),
                  title: submission.label,
                  phase: MutationActivityPhase.resolve([submission], const []),
                  message: submission.integrationFailed
                      ? "Saved. Local refresh failed."
                      : submission.sending
                      ? "Saving"
                      : switch (submission.result) {
                          LocalWorkSubmissionResult.confirmed => "Saved",
                          LocalWorkSubmissionResult.rejected =>
                            submission.message ?? "Rejected",
                          LocalWorkSubmissionResult.uncertain =>
                            submission.canReplay
                                ? "Outcome unknown. Retry sends the same "
                                      "request, which is safe to repeat."
                                : "Outcome unknown. Verify before submitting "
                                      "again.",
                          LocalWorkSubmissionResult.notSubmitted =>
                            submission.message ?? "Not submitted",
                          LocalWorkSubmissionResult.ready => "Ready",
                        },
                  actions: [
                    if (submission.integrationFailed)
                      Button(
                        icon: const Icon(Icons.refresh, size: 16),
                        label: "Refresh saved result",
                        onPressed: () =>
                            controller.retrySubmission(submission.id),
                      )
                    else if (submission.canReplay)
                      Button(
                        icon: const Icon(Icons.refresh, size: 16),
                        label: "Retry captured request",
                        onPressed: () =>
                            controller.retrySubmission(submission.id),
                      )
                    else if (!submission.sending &&
                        submission.result !=
                            LocalWorkSubmissionResult.uncertain)
                      Button(
                        label: "Dismiss",
                        onPressed: () => controller.dismiss(submission.id),
                      ),
                  ],
                ),
              if (drafts.isEmpty && state.submissions.isEmpty)
                Padding(
                  padding: EdgeInsets.all(context.spacing.space4),
                  child: Text(
                    "No pending changes",
                    style: context.theme.textTheme.bodyMedium?.copyWith(
                      color: context.colors.contentSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
