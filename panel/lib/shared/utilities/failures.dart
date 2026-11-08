/// A failure whose [message] is written for the user, such as a service's
/// refusal; it is shown as it is.
abstract interface class ShownFailure implements Exception {
  String get message;
}

/// A failure whose outcome is unknown: the request may have landed. The
/// save status reports it, not the action that sent it.
abstract interface class UnconfirmedFailure implements Exception {}
