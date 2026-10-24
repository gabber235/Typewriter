import "package:typewriter_panel/typewriter_panel.dart";

/// Utilities for surfacing expected panel operation failures at a widget boundary.
extension FutureExt<T> on Future<T> {
  /// Shows an error snackbar for known API and mutation failures.
  ///
  /// Successful values and unrecognized failures pass through. Recognized
  /// failures are handled without a replacement value, so use this with void
  /// operations. An unmounted [context] suppresses only the snackbar.
  Future<T> catchApiExceptionsAndDisplay(BuildContext context) {
    return catchError(
      (error, stackTrace) {
        if (!context.mounted) return;
        showErrorSnackBar(context, error.toString());
      },
      test: (error) =>
          error is ApiException ||
          error is SubmissionException ||
          error is EditorMutationException,
    );
  }
}
