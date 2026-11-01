import "package:typewriter_panel/typewriter_panel.dart";

/// Owns delivery of one prepared request, independently of later user edits.
///
/// The supplied sender must capture an immutable request and destination.
/// Repeated attempts reuse that sender. Only protocols with verified replay
/// support may retry an uncertain result; a submission given a redelivery
/// scheduler resends such a result on its own, with [redeliveryDelay] between
/// attempts, until a known answer arrives. Concurrent attempts share one Future.
/// Known results enter local integration independently of delivery. Successful
/// integration is retained; failed integration can run again without resending
/// an already accepted mutation. Disposal stops publication and releases owned
/// dependencies but cannot retract a request already sent to the server.
final class MutationSubmission<T> extends ChangeNotifier {
  MutationSubmission({
    required this.id,
    required this.label,
    required this._send,
    this._integrate,
    this._onDispose,
    this._redelivery,
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

  /// Schedules sending an unanswered request again; without it, only [run]
  /// sends.
  final EditorDelayScheduler? _redelivery;

  /// The scheduled resend of the unanswered request.
  EditorScheduledTask? _resend;

  /// Consecutive attempts that got no answer; paces [_resend].
  int _unanswered = 0;
  SdkAsyncError? _integrationError;
  SdkAsyncError? get integrationError => _integrationError;
  Future<SubmissionResult<T>>? _active;
  SubmissionResult<T>? _result;
  bool _disposed = false;

  SubmissionResult<T>? get result => _result;
  bool get sending => _active != null;

  /// Whether the request is on its way: being sent now, or unanswered and
  /// scheduled to be sent again on its own.
  bool get delivering => sending || _resend != null;
  bool get unsettled => sending || _result is! SubmissionConfirmed<T>;
  bool get canReplay =>
      !sending &&
      _integrationError == null &&
      (_result is SubmissionNotSubmitted<T> ||
          _result is SubmissionUndelivered<T> ||
          (_result is SubmissionUncertain<T> &&
              replay == SubmissionReplay.identicalRequest));

  /// The pause before sending again an attempt nothing answered or received:
  /// 250 ms, doubling, at most 10 s.
  static Duration redeliveryDelay(int attempt) =>
      Duration(milliseconds: min(250 << min(attempt - 1, 6), 10000));

  /// Starts delivery or returns the active or settled attempt.
  ///
  /// Calls made while sending share the same future. An uncertain result is
  /// replayable only when [replay] explicitly permits an identical request.
  /// Integration may be retried without sending again. With a redelivery
  /// scheduler, an uncertain result is sent again on its own while it may be
  /// replayed; sending now replaces a scheduled resend.
  Future<SubmissionResult<T>> run() {
    if (_disposed) throw StateError("Submission is disposed");
    final active = _active;
    if (active != null) return active;
    if (_integrationError != null) return retryIntegration();
    final previous = _result;
    if (previous != null && !canReplay && _integrationError == null) {
      return Future.value(previous);
    }
    // Sending now replaces a scheduled resend, as when Retry comes first.
    _resend?.cancel();
    _resend = null;
    final operation = previous != null && !canReplay
        ? Future.value(previous)
        : Future<SubmissionResult<T>>.sync(_send).then(
            (result) => switch (result) {
              // An earlier attempt went unanswered and may have landed, so an
              // attempt nothing received leaves the outcome unknown.
              SubmissionUndelivered(:final message, :final cause) ||
              SubmissionNotSubmitted(:final message, :final cause)
                  when previous is SubmissionUncertain<T> =>
                SubmissionResult<T>.uncertain(
                  message: message,
                  cause: cause ?? message,
                  stackTrace: StackTrace.current,
                ),
              _ => result,
            },
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
        _scheduleResend(result);
        notifyListeners();
      }
      return result;
    });

    notifyListeners();
    return _active!;
  }

  /// Sends the same request again after [redeliveryDelay] while nothing
  /// answered it and replay is safe. A known answer ends the resends.
  void _scheduleResend(SubmissionResult<T> result) {
    if (result is! SubmissionUncertain<T>) {
      _unanswered = 0;
      return;
    }
    final scheduler = _redelivery;
    if (scheduler == null || !canReplay) return;
    final task = _resend = scheduler.schedule(redeliveryDelay(++_unanswered));
    unawaited(
      task.completed.then((completion) {
        if (_disposed || !identical(_resend, task)) return;
        _resend = null;
        if (completion == EditorTaskCompletion.executed) unawaited(run());
      }),
    );
  }

  /// Applies the captured known response again without sending the request.
  Future<SubmissionResult<T>> retryIntegration() {
    if (_disposed) throw StateError("Submission is disposed");
    if (_active case final active?) return active;
    final previous = _result;
    if (previous == null || previous is SubmissionUncertain<T>) {
      throw StateError("Local integration requires a known response");
    }
    if (_integrationError == null) return Future.value(previous);
    _active = _integrateResult(previous).then((result) {
      if (!_disposed) {
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

  /// Stops notifications and resends, and releases the prepared commit's owned
  /// resources.
  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _resend?.cancel();
    _resend = null;
    _onDispose?.call();
    super.dispose();
  }
}
