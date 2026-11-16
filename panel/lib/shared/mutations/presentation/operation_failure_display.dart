import "package:typewriter_panel/typewriter_panel.dart";

/// Utilities for surfacing expected panel operation failures at a widget boundary.
extension FutureExt<T> on Future<T> {
  /// Toasts known API and mutation failures; they land in Activity.
  ///
  /// Successful values and unrecognized failures pass through. Recognized
  /// failures are handled without a replacement value, so use this with void
  /// operations. An unmounted [context] suppresses only the toast.
  Future<T> catchApiExceptionsAndDisplay(BuildContext context) {
    return catchError(
      (error, stackTrace) {
        // The save status reports a failure whose outcome is unknown.
        if (!context.mounted || error is UnconfirmedFailure) return;
        context.reportFailure(
          "Action failed",
          detail: error is ShownFailure ? error.message : error.toString(),
        );
      },
      test: (error) =>
          error is ApiException ||
          error is SubmissionException ||
          error is EditorMutationException,
    );
  }
}
