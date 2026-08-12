part of "../../data_renderer.dart";

extension DiagnosticElementRendering on DiagnosticElement {
  Widget render(BuildContext context) =>
      presentationDiagnostic(context, diagnostics);
}
