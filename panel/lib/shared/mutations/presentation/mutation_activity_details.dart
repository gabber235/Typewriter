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
    final source = controller.source(resource.id.identity as EditorResourceKey);
    if (source == null) return;
    final host = controller.resources[resource.id.identity as EditorResourceKey]
        ?.buildPortablePresentationHost();
    if (host == null) return;
    controller.retain(resource.id.identity as EditorResourceKey);
    try {
      await showAdvancedDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(resource.label),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: PortablePresentationRenderer(host: host),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        ),
      );
    } finally {
      host.dispose();
      controller.release(resource.id.identity as EditorResourceKey);
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
              IconButton(
                tooltip: "Close",
                onPressed: onClose,
                icon: const Icon(Icons.close, size: 20),
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
                          TextButton.icon(
                            icon: const Icon(Icons.save_outlined, size: 16),
                            onPressed: () => controller.save(resource.id),
                            label: const Text("Save"),
                          ),
                        if (resource.canRetry)
                          TextButton.icon(
                            icon: const Icon(Icons.refresh, size: 16),
                            onPressed: () => controller.retry(resource.id),
                            label: const Text("Retry"),
                          ),
                        if (resource.destination ==
                            LocalWorkDestinationState.available)
                          TextButton.icon(
                            icon: const Icon(Icons.arrow_outward, size: 16),
                            onPressed: () async {
                              onClose();
                              await controller.open(resource.id);
                            },
                            label: const Text("Open work"),
                          )
                        else if (resource.id.identity is EditorResourceKey &&
                            resource.destination ==
                                LocalWorkDestinationState.unavailable)
                          TextButton.icon(
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            onPressed: () => _review(context, resource),
                            label: const Text("Review draft"),
                          ),
                        if (resource.canDiscard)
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: context.theme.colorScheme.error,
                            ),
                            onPressed: resource.canDiscard
                                ? () => controller.discard(resource.id)
                                : null,
                            child: const Text("Discard"),
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
                            "Outcome unknown. Verify before submitting again.",
                          LocalWorkSubmissionResult.notSubmitted =>
                            submission.message ?? "Not submitted",
                          LocalWorkSubmissionResult.ready => "Ready",
                        },
                  actions: [
                    if (submission.integrationFailed)
                      TextButton.icon(
                        icon: const Icon(Icons.refresh, size: 16),
                        onPressed: () =>
                            controller.retrySubmission(submission.id),
                        label: const Text("Refresh saved result"),
                      )
                    else if (submission.canReplay)
                      TextButton.icon(
                        icon: const Icon(Icons.refresh, size: 16),
                        onPressed: () =>
                            controller.retrySubmission(submission.id),
                        label: const Text("Retry captured request"),
                      )
                    else if (!submission.sending &&
                        submission.result !=
                            LocalWorkSubmissionResult.uncertain)
                      TextButton(
                        onPressed: () => controller.dismiss(submission.id),
                        child: const Text("Dismiss"),
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
