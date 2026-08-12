import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class PresentationSurface extends StatelessWidget {
  const PresentationSurface({
    required this.presentation,
    required this.scope,
    this.diagnostics = const [],
    super.key,
  });

  final PresentationNode presentation;
  final PresentationRenderScope scope;
  final List<TypeDiagnostic> diagnostics;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (diagnostics.isNotEmpty) ...[
        presentationDiagnostic(context, diagnostics),
        const SizedBox(height: 12),
      ],
      PresentationNodeRenderer(node: presentation, scope: scope),
    ],
  );
}
