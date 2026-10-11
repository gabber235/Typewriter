import "package:typewriter_panel/typewriter_panel.dart";

/// Owns delivery of one prepared request, independently of later user edits.
///
/// The supplied sender must capture an immutable request and destination.
/// Repeated attempts reuse that sender. Only protocols with verified replay
/// support may retry an uncertain result. Concurrent attempts share one Future.
/// A confirmed response is integrated once; integration failure is reported
/// separately because resending could duplicate an already accepted mutation.
final class MutationSubmission<T> extends ChangeNotifier {
  MutationSubmission({
    required this.id,
    required this.label,
    required this._send,
    this._integrate,
    this._onDispose,
    this.replay = SubmissionReplay.unsupported,
    Set<Object> resources = const {},
  }) : resources = Set.unmodifiable(resources);

  final Object id;
  final Set<Object> resources;
  final String label;
  final SubmissionReplay replay;
  final Future<SubmissionResult<T>> Function() _send;
  final Future<void> Function(SubmissionResult<T>)? _integrate;
  final void Function()? _onDispose;
  SdkAsyncError? _integrationError;
  SdkAsyncError? get integrationError => _integrationError;
  Future<SubmissionResult<T>>? _active;
  SubmissionResult<T>? _result;
  bool _disposed = false;

  SubmissionResult<T>? get result => _result;
  bool get sending => _active != null;
  bool get unsettled => sending || _result is! SubmissionConfirmed<T>;
  bool get canReplay =>
      !sending &&
      (_result is SubmissionNotSubmitted<T> ||
          (_result is SubmissionUncertain<T> &&
              replay == SubmissionReplay.identicalRequest));

  /// Starts delivery or returns the active or settled attempt.
  ///
  /// Calls made while sending share the same future. An uncertain result is
  /// replayable only when [replay] explicitly permits an identical request.
  /// Integration may be retried without sending again.
  Future<SubmissionResult<T>> run() {
    if (_disposed) throw StateError("Submission is disposed");
    final active = _active;
    if (active != null) return active;
    final previous = _result;
    if (previous != null && !canReplay && _integrationError == null) {
      return Future.value(previous);
    }
    final operation = previous != null && !canReplay
        ? Future.value(previous)
        : Future<SubmissionResult<T>>.sync(_send).then(
            (result) => result,
            onError: (Object error, StackTrace stackTrace) =>
                SubmissionResult<T>.uncertain(
                  message: "The operation result could not be confirmed",
                  cause: error,
                  stackTrace: stackTrace,
                ),
          );

    _active = operation.then(_integrateResult).then((result) {
      if (!_disposed) {
        _result = result;
        _active = null;
        notifyListeners();
      }
      return result;
    });

    notifyListeners();
    return _active!;
  }

  Future<SubmissionResult<T>> _integrateResult(
    SubmissionResult<T> result,
  ) async {
    if (_disposed || result is SubmissionUncertain<T>) return result;
    try {
      await _integrate?.call(result);
      _integrationError = null;
    } on Object catch (error, stackTrace) {
      if (_disposed) return result;
      _integrationError = SdkAsyncError(error, stackTrace);
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
    }
    if (!_disposed) notifyListeners();
    return result;
  }

  /// Stops notifications and releases the prepared commit's owned resources.
  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _onDispose?.call();
    super.dispose();
  }
}
