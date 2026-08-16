part of "../../input_renderer.dart";

extension SearchInputElementRendering on SearchInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    return BoundControlShell(
      control: control,
      scope: scope,
      builder: (context, field) {
        final extentValue = scope.evaluate(maximumExtent);
        if (extentValue case TypeFailure(:final diagnostics)) {
          return presentationDiagnostic(context, diagnostics);
        }
        final extent = switch (extentValue.valueOrNull) {
          FloatValue(:final value) => value,
          IntegerValue(:final value) => value.toDouble(),
          _ => null,
        };
        if (extent == null || !extent.isFinite || extent <= 0) {
          return presentationDiagnostic(context, [
            const TypeDiagnostic(
              code: TypeDiagnosticCode.invalidValue,
              message: "Search maximum extent must be a positive number",
            ),
          ]);
        }
        return PresentationSearchInput(
          element: this,
          binding: field.binding,
          scope: scope,
          maximumExtent: extent,
        );
      },
    );
  }
}
