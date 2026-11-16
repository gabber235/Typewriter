import "package:typewriter_panel/typewriter_panel.dart";

/// A failure whose [message] is written for the user, such as a service's
/// refusal; it is shown as it is.
abstract interface class ShownFailure implements Exception {
  String get message;
}

/// A failure whose outcome is unknown: the request may have landed. The
/// save status reports it, not the action that sent it.
abstract interface class UnconfirmedFailure implements Exception {}

/// The sentence shown for a failed action: the failure's own words when it
/// was written for the user, else a plain sentence. Anything else is logged
/// with its stack, never shown raw.
String failureMessage(Object error, StackTrace stack) {
  if (error is ShownFailure) return error.message;
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: error,
      stack: stack,
      library: "Typewriter action",
      context: ErrorDescription("running an action"),
    ),
  );
  return "This did not go through. Try again.";
}
