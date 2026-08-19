import "dart:async";

import "package:flutter/foundation.dart";

enum PanelMutationOperation {
  createTag,
  deleteService,
  deleteTag,
  signOut,
  updateService,
  updateTag,
}

extension on PanelMutationOperation {
  String get description => switch (this) {
    PanelMutationOperation.createTag => "creating a tag",
    PanelMutationOperation.deleteService => "deleting a service",
    PanelMutationOperation.deleteTag => "deleting a tag",
    PanelMutationOperation.signOut => "signing out",
    PanelMutationOperation.updateService => "updating a service",
    PanelMutationOperation.updateTag => "updating a tag",
  };
}

typedef PanelMutationRecovery<T> =
    FutureOr<T> Function(Object error, StackTrace stackTrace);

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
