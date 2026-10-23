import "package:typewriter_panel/typewriter_panel.dart";

/// A deliberate exception adapter for callers that require an applied mutation.
///
/// The original [result] remains attached so recovery can distinguish conflict,
/// uncertainty, invalid input, permission denial, and unavailability. The
/// exception carries presentation ready [message], but callers that can handle
/// failure should prefer matching the typed result directly.
final class EditorMutationException implements Exception {
  const EditorMutationException(this.result, this.message);
  final TypedMutationResult result;
  final String message;
  @override
  String toString() => message;
}

/// Converts a non successful mutation result into a typed exception.
///
/// Use this only at a boundary whose contract is success or throw. It never
/// treats an uncertain outcome as a safe failure because the remote side may
/// already have applied the operation. Callers that can recover should inspect
/// [TypedMutationResult] without using this adapter.
extension RequireEditorMutation on TypedMutationResult {
  void requireApplied({required String conflictMessage}) {
    final message = switch (this) {
      MutationSuccess() => null,
      MutationConflict() => conflictMessage,
      MutationUncertain(:final message) ||
      MutationPermissionDenied(:final message) => message,
      MutationInvalid(:final diagnostics) ||
      MutationUnavailable(
        :final diagnostics,
      ) => diagnostics.map((diagnostic) => diagnostic.message).join("; "),
    };
    if (message != null) throw EditorMutationException(this, message);
  }
}
