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
                destination: owned.driver is DocumentWorkDriver
                    ? entry.destination
                    : owned.destination == null
                    ? LocalWorkDestinationState.unavailable
                    : owned.destination!.isCurrent
                    ? LocalWorkDestinationState.current
                    : LocalWorkDestinationState.available,
              ),
      },
      editorValues: {
        for (final entry in _resources.entries)
          if (entry.value.source.editedPaths case final paths
              when paths.isNotEmpty)
            if (entry.value.source
                    .value(skir.ValuePath(segments: []))
                    .valueOrNull
                case final value?)
              entry.key: LocalEditorValue(value: value, editedPaths: paths),
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
    return LocalWorkSubmissionState(
      id: submission.id,
      label: submission.label,
      sending: submission.sending,
      canReplay: submission.canReplay,
      integrationFailed: submission.integrationError != null,
      result: switch (result) {
        null => LocalWorkSubmissionResult.ready,
        SubmissionConfirmed() => LocalWorkSubmissionResult.confirmed,
        SubmissionRejected() => LocalWorkSubmissionResult.rejected,
        SubmissionUncertain() => LocalWorkSubmissionResult.uncertain,
        SubmissionNotSubmitted() => LocalWorkSubmissionResult.notSubmitted,
      },
      message: switch (result) {
        SubmissionRejected(:final message) ||
        SubmissionNotSubmitted(:final message) ||
        SubmissionUncertain(:final message) => message,
        _ => null,
      },
    );
  }
}
