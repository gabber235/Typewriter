import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Makes diagnostics for one presentation input available to bound controls.
///
/// Type diagnostics use paths in the owning document. Presentation bindings
/// use paths relative to their input. This scope performs that rebase once and
/// lets controls query their canonical binding address without parsing labels
/// or diagnostic messages.
class PresentationFieldDiagnostics extends InheritedWidget {
  PresentationFieldDiagnostics({
    required BindingId bindingId,
    required DataPath sourcePath,
    required Iterable<TypeDiagnostic> diagnostics,
    required super.child,
    this.descendantDiagnostics = const [],
    super.key,
  }) : _entries = [
         for (final diagnostic in diagnostics)
           if (diagnostic.pathPresent &&
               diagnostic.path.isAtOrBelow(sourcePath))
             _FieldDiagnosticEntry(
               reference: BindingReference(
                 bindingId: bindingId,
                 path: DataPath(
                   diagnostic.path.segments
                       .skip(sourcePath.segments.length)
                       .toList(),
                 ),
               ),
               diagnostic: diagnostic,
               exact: true,
             ),
         for (final diagnostic in descendantDiagnostics)
           if (diagnostic.pathPresent &&
               diagnostic.path.isAtOrBelow(sourcePath))
             _FieldDiagnosticEntry(
               reference: BindingReference(
                 bindingId: bindingId,
                 path: DataPath(
                   diagnostic.path.segments
                       .skip(sourcePath.segments.length)
                       .toList(),
                 ),
               ),
               diagnostic: diagnostic,
               exact: false,
             ),
       ];

  final Iterable<TypeDiagnostic> descendantDiagnostics;
  final List<_FieldDiagnosticEntry> _entries;

  static PresentationFieldDiagnostics? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<PresentationFieldDiagnostics>();

  List<TypeDiagnostic> exact(BindingReference reference) => [
    for (final entry in _entries)
      if (entry.exact && entry.reference == reference) entry.diagnostic,
  ];

  List<TypeDiagnostic> atOrBelow(BindingReference reference) => [
    for (final entry in _entries)
      if (entry.reference.bindingId == reference.bindingId &&
          entry.reference.path.isAtOrBelow(reference.path))
        entry.diagnostic,
  ];

  @override
  bool updateShouldNotify(PresentationFieldDiagnostics oldWidget) =>
      oldWidget._entries != _entries;
}

@immutable
class _FieldDiagnosticEntry {
  const _FieldDiagnosticEntry({
    required this.reference,
    required this.diagnostic,
    required this.exact,
  });

  final BindingReference reference;
  final TypeDiagnostic diagnostic;
  final bool exact;
}
