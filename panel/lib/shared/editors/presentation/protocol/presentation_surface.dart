import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Routes diagnostics and hosts the root node for one render scope.
///
/// Input diagnostics with usable paths enter [PresentationFieldDiagnostics]
/// for placement beside bound controls. Unscoped diagnostics and paths outside
/// the presented input remain in the banner before the tree. The render scope
/// continues to own evaluation, mutation routing, and interaction lifecycle.
class PresentationSurface extends StatelessWidget {
  const PresentationSurface({
    required this.presentation,
    required this.scope,
    this.diagnostics = const [],
    this.inputDiagnostics = const [],
    this.diagnosticBindingId,
    this.diagnosticSourcePath = DataPath.root,
    super.key,
  });

  final PresentationNode presentation;
  final PresentationRenderScope scope;
  final List<TypeDiagnostic> diagnostics;
  final List<TypeDiagnostic> inputDiagnostics;
  final BindingId? diagnosticBindingId;
  final DataPath diagnosticSourcePath;

  @override
  Widget build(BuildContext context) {
    final bindingId = diagnosticBindingId;
    final local = bindingId == null
        ? const <TypeDiagnostic>[]
        : inputDiagnostics
              .where(
                (diagnostic) =>
                    diagnostic.pathPresent &&
                    diagnostic.path.isAtOrBelow(diagnosticSourcePath),
              )
              .toList();
    final descendantDiagnostics = [
      for (final diagnostic in local)
        if (_belongsToIncompleteMapEntry(diagnostic)) diagnostic,
    ];
    final placed = [
      for (final diagnostic in local)
        if (!_belongsToIncompleteMapEntry(diagnostic)) diagnostic,
    ];
    final global = [
      ...diagnostics,
      for (final diagnostic in inputDiagnostics)
        if (!local.contains(diagnostic)) diagnostic,
    ];
    Widget editor = PresentationNodeRenderer(node: presentation, scope: scope);
    if (bindingId != null) {
      editor = PresentationFieldDiagnostics(
        bindingId: bindingId,
        sourcePath: diagnosticSourcePath,
        diagnostics: placed,
        descendantDiagnostics: descendantDiagnostics,
        child: editor,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (global.isNotEmpty) ...[
          presentationDiagnostic(context, global),
          SizedBox(height: context.spacing.space3),
        ],
        editor,
      ],
    );
  }

  bool _belongsToIncompleteMapEntry(TypeDiagnostic diagnostic) {
    if (diagnostic.code != TypeDiagnosticCode.missingField ||
        diagnosticBindingId == null) {
      return false;
    }
    final owner = scope.editOwnerFor?.call(
      BindingReference(bindingId: diagnosticBindingId!),
    );
    if (owner is! EditorStructureOwner) return false;
    final structure = owner.mapStructure(diagnostic.path);
    return structure?.entries.any(
          (entry) =>
              entry.key is MissingEditorValue ||
              entry.value is MissingEditorValue,
        ) ??
        false;
  }
}
