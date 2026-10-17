import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

extension EditorMutationPortablePresentation on EditorMutationResult {
  PortablePresentationWriteResult toPortablePresentationResult({
    required skir.ExpressionBindingId binding,
    required skir.ValuePath sourcePath,
  }) => switch (this) {
    AppliedEditorMutation() => const PortablePresentationWriteResult.applied(),
    ConflictingEditorMutation() => PortablePresentationWriteResult.rejected([
      PortablePresentationDiagnostic(
        code: "editing_conflict",
        message: "The value changed while it was being edited",
        severity: skir.DiagnosticSeverity.error,
        targets: const [],
      ),
    ]),
    InvalidEditorMutation(:final diagnostics) =>
      PortablePresentationWriteResult.rejected([
        for (final diagnostic in diagnostics)
          diagnostic.forPortableBinding(
            binding: binding,
            sourcePath: sourcePath,
          ),
      ]),
  };
}

extension PortableEditorDiagnosticMapping on EditorDiagnostic {
  PortablePresentationDiagnostic forPortableBinding({
    required skir.ExpressionBindingId binding,
    required skir.ValuePath sourcePath,
  }) {
    final absolute = path;
    final belongsToBinding =
        absolute != null && absolute.isAtOrBelow(sourcePath);
    return PortablePresentationDiagnostic(
      code: code.name,
      message: message,
      severity: switch (severity) {
        EditorDiagnosticSeverity.information =>
          skir.DiagnosticSeverity.information,
        EditorDiagnosticSeverity.warning => skir.DiagnosticSeverity.warning,
        EditorDiagnosticSeverity.error => skir.DiagnosticSeverity.error,
      },
      details: details,
      targets: belongsToBinding
          ? [
              PortableDiagnosticTarget.binding(
                skir.BindingRef(
                  bindingId: binding,
                  path: skir.ValuePath(
                    segments: absolute.segments.skip(
                      sourcePath.segments.length,
                    ),
                  ),
                ),
              ),
            ]
          : const [],
    );
  }
}
