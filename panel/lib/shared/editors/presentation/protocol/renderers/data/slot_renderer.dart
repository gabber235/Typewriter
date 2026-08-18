part of "../../data_renderer.dart";

extension PresentationSlotElementRendering on PresentationSlotElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final content = scope.presentationSlots[slotId];
    if (content != null) return content;
    return presentationDiagnostic(context, [
      TypeDiagnostic(
        code: TypeDiagnosticCode.invalidValue,
        message: "Presentation slot $slotId has no content",
      ),
    ]);
  }
}
