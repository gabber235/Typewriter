import "dart:async";

import "package:flutter/foundation.dart";

/// User visible operation context attached to an unexpected panel mutation error.
enum PanelMutationOperation { deleteService, signOut, updateService }

extension on PanelMutationOperation {
  String get description => switch (this) {
    PanelMutationOperation.deleteService => "deleting a service",
    PanelMutationOperation.signOut => "signing out",
    PanelMutationOperation.updateService => "updating a service",
  };
}

/// Handles a mutation failure and returns the caller's recovered result.
typedef PanelMutationRecovery<T> = FutureOr<T> Function(
  Object error,
  StackTrace stackTrace,
);

/// Runs a panel mutation with one centralized unexpected failure boundary.
///
/// Successful results pass through unchanged. Failures are reported with the
/// safe [operation] description. [recover] may convert a failure into a normal
/// result and receives the original error and stack. Without [recover], the
/// original error and stack are rethrown.
Future<T> runPanelMutation<T>({
  required PanelMutationOperation operation,
  required Future<T> Function() mutation,
  PanelMutationRecovery<T>? recover,
}) async {
  try {
    return await mutation();
  } on Object catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: "Typewriter panel mutation",
        context: ErrorDescription("while ${operation.description}"),
      ),
    );
    if (recover != null) return recover(error, stackTrace);
    Error.throwWithStackTrace(error, stackTrace);
  }
}
