part of "local_work_session.dart";

/// Publishes the session's canonical read model without exposing mutable owners.
///
/// Expiry timers belong to the session and are created only for settled
/// submissions. Resource and editor projections are rebuilt from their current
/// sources, so stale snapshots cannot become authoritative.
extension _LocalWorkSnapshot on ScopedWorkSession {
  void _publish() {
    if (_disposed) return;
    for (final submission in _submissions.values) {
      if (submission.result is SubmissionConfirmed &&
          !submission.sending &&
          submission.integrationError == null) {
        _expiry.putIfAbsent(
          submission.id,
          () => Timer(savedFeedbackDuration, () => dismiss(submission.id)),
        );
      }
    }
    final next = LocalWorkState(
      entries: {
        for (final owned in _drivers.values)
          for (final entry in owned.driver.snapshot.entries)
            if (entry.retained || entry.hasWork)
              entry.id: entry.copyWith(
                destination: owned.destination == null
                    ? LocalWorkDestinationState.unavailable
                    : owned.destination!.isCurrent
                    ? LocalWorkDestinationState.current
                    : LocalWorkDestinationState.available,
              ),
      },
      editorValues: {
        for (final owned in _drivers.values)
          ...owned.driver.snapshot.editorValues,
      },
      submissions: _submissions.values.map(_submissionState).toList(),
    );
    if (next == _state) return;
    _state = next;
    _changes.add(next);
  }

  LocalWorkSubmissionState _submissionState(
    MutationSubmission<Object?> submission,
  ) {
    final result = submission.result;
    final phase = submission.sending
        ? const LocalWorkSubmissionPhase.active()
        : switch (result) {
            null => const LocalWorkSubmissionPhase.prepared(),
            SubmissionUncertain(:final message) =>
              LocalWorkSubmissionPhase.uncertain(message, submission.replay),
            final known => LocalWorkSubmissionPhase.settled(
              switch (known) {
                SubmissionConfirmed() =>
                  const LocalWorkKnownOutcome.confirmed(),
                SubmissionRejected(:final message) =>
                  LocalWorkKnownOutcome.rejected(message),
                SubmissionNotSubmitted(:final message) =>
                  LocalWorkKnownOutcome.notSubmitted(message),
                _ => throw StateError(
                  "A settled submission requires a known delivery outcome",
                ),
              },
              submission.integrationError != null
                  ? LocalWorkIntegration.failed(
                      submission.integrationError!.error.toString(),
                    )
                  : const LocalWorkIntegration.applied(),
            ),
          };
    return LocalWorkSubmissionState(
      id: submission.id,
      label: submission.label,
      resources: submission.resources,
      phase: phase,
    );
  }
}
