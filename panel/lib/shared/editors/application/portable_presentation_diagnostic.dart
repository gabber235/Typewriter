import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "portable_presentation_diagnostic.freezed.dart";

/// Identifies one field independently of the particular widget displaying it.
/// Authored targets include their resource; backend targets belong to the host binding.
@freezed
sealed class PortableDiagnosticTarget with _$PortableDiagnosticTarget {
  const PortableDiagnosticTarget._();

  const factory PortableDiagnosticTarget.binding(skir.BindingRef reference) =
      PortableBindingDiagnosticTarget;
  const factory PortableDiagnosticTarget.value(skir.ValueLocation location) =
      PortableValueDiagnosticTarget;

  skir.ValuePath get path => switch (this) {
    PortableBindingDiagnosticTarget(:final reference) => reference.path,
    PortableValueDiagnosticTarget(:final location) => location.path,
  };

  bool isAtOrBelow(PortableDiagnosticTarget ancestor) => switch ((
    this,
    ancestor,
  )) {
    (
      PortableBindingDiagnosticTarget(reference: final child),
      PortableBindingDiagnosticTarget(reference: final parent),
    ) =>
      child.bindingId == parent.bindingId &&
          child.path.isAtOrBelow(parent.path),
    (
      PortableValueDiagnosticTarget(location: final child),
      PortableValueDiagnosticTarget(location: final parent),
    ) =>
      child.resource == parent.resource && child.path.isAtOrBelow(parent.path),
    _ => false,
  };
}

/// Carries a finding from its validator to exact fields and enclosing headers.
/// An empty target list means that the message belongs to the presentation as a whole.
@freezed
abstract class PortablePresentationDiagnostic
    with _$PortablePresentationDiagnostic {
  const factory PortablePresentationDiagnostic({
    required String code,
    required String message,
    required skir.DiagnosticSeverity severity,
    @Default([]) List<PortableDiagnosticTarget> targets,
    @Default({}) Map<String, String> details,
    skir.DiagnosticId? id,
    skir.RuleOrigin? origin,
  }) = _PortablePresentationDiagnostic;
}
