import "package:typewriter_panel/typewriter_panel.dart";

extension PreparedCommitMapping<T> on PreparedCommit<T> {
  /// Changes response meaning while preserving request identity and integration.
  PreparedCommit<R> mapResponse<R>(R Function(T) map) {
    SubmissionResult<T>? received;
    return PreparedCommit<R>(
      id: id,
      label: label,
      resources: resources,
      replay: replay,
      dispose: dispose,
      send: () async {
        final result = await send();
        received = result;
        return result.mapResponse(map);
      },
      integrate: (_) async {
        if (received case final result?) await integrate?.call(result);
      },
    );
  }
}

extension SubmissionResponseMapping<T> on SubmissionResult<T> {
  SubmissionResult<R> mapResponse<R>(R Function(T) map) => switch (this) {
    SubmissionConfirmed(:final value) => SubmissionResult.confirmed(map(value)),
    SubmissionRejected(:final message, :final cause, :final response) =>
      SubmissionResult.rejected(
        message: message,
        cause: cause,
        response: response == null ? null : map(response),
      ),
    SubmissionNotSubmitted(:final message, :final cause) =>
      SubmissionResult.notSubmitted(message: message, cause: cause),
    SubmissionUncertain(:final message, :final cause, :final stackTrace) =>
      SubmissionResult.uncertain(
        message: message,
        cause: cause,
        stackTrace: stackTrace,
      ),
  };
}
