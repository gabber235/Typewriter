import "dart:async";

import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

extension FutureExt<T> on Future<T> {
  Future<T> catchApiExceptionsAndDisplay(BuildContext context) {
    return catchError((error, stackTrace) {
      showErrorSnackBar(context, error.message);
    }, test: (error) => error is ApiException);
  }
}

extension IterableFutureExt<T> on Iterable<Future<T>> {
  Future<List<T>> awaitAll({
    bool eagerError = false,
    void Function(T)? cleanUp,
  }) {
    return Future.wait(this, eagerError: eagerError, cleanUp: cleanUp);
  }
}

extension FirstValueTimeoutStreamExtension<T> on Stream<T> {
  /// Throws a [TimeoutException] if the first value is not emitted within
  /// [duration].
  ///
  /// Pausing the subscription cancels the active timeout. Resuming starts a
  /// new timeout using the full [duration].
  Stream<T> timeoutFirstValue(Duration duration, {String? message}) {
    assert(!duration.isNegative, "duration must not be negative");

    return Stream<T>.multi((controller) {
      StreamSubscription<T>? subscription;
      Timer? timeoutTimer;

      var isWaitingForFirstValue = true;
      var isTerminated = false;

      void cancelTimeout() {
        timeoutTimer?.cancel();
        timeoutTimer = null;
      }

      void terminate() {
        if (isTerminated) {
          return;
        }

        isTerminated = true;
        cancelTimeout();
      }

      void handleTimeout() {
        if (!isWaitingForFirstValue || isTerminated) {
          return;
        }

        terminate();

        controller
          ..addError(
            TimeoutException(
              message ?? "No first stream value was emitted within $duration",
              duration,
            ),
          )
          ..close();

        unawaited(subscription?.cancel());
      }

      void startTimeout() {
        if (!isWaitingForFirstValue || isTerminated) {
          return;
        }

        assert(timeoutTimer == null);

        timeoutTimer = Timer(duration, handleTimeout);
      }

      void handleValue(T value) {
        if (isTerminated) {
          return;
        }

        if (isWaitingForFirstValue) {
          isWaitingForFirstValue = false;
          cancelTimeout();
        }

        controller.add(value);
      }

      void handleError(Object error, StackTrace stackTrace) {
        if (isTerminated) {
          return;
        }

        controller.addError(error, stackTrace);
      }

      void handleDone() {
        if (isTerminated) {
          return;
        }

        terminate();
        controller.close();
      }

      void handlePause() {
        cancelTimeout();
        subscription?.pause();
      }

      void handleResume() {
        subscription?.resume();
        startTimeout();
      }

      Future<void> handleCancel() async {
        terminate();
        await subscription?.cancel();
      }

      controller
        ..onPause = handlePause
        ..onResume = handleResume
        ..onCancel = handleCancel;

      subscription = listen(
        handleValue,
        onError: handleError,
        onDone: handleDone,
      );

      startTimeout();
    }, isBroadcast: isBroadcast);
  }
}
