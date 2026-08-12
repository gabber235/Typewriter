import "package:flutter/material.dart";
import "package:iconify_flutter_plus/icons/heroicons_solid.dart";
import "package:iconify_flutter_plus/icons/ion.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "renderers/input/collection_support.dart";
part "renderers/input/list_input_renderer.dart";
part "renderers/input/record_input_renderer.dart";
part "renderers/input/map_input_renderer.dart";

extension CompositeInputRendering on PresentationElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final control = switch (this) {
      ListInputElement(:final control) ||
      MapInputElement(:final control) ||
      RecordInputElement(:final control) => control,
      _ => null,
    };
    if (control == null) return const SizedBox.shrink();
    final resolved = scope.resolve(control.binding);
    if (resolved case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final binding = resolved.valueOrNull!;
    return switch ((this, binding.type, binding.value)) {
      (ListInputElement(), ListType(), ListValue()) =>
        (this as ListInputElement).render(binding: binding, scope: scope),
      (MapInputElement(), MapType(), MapValue()) =>
        (this as MapInputElement).render(binding: binding, scope: scope),
      (RecordInputElement(), RecordType(), RecordValue()) =>
        (this as RecordInputElement).render(binding: binding, scope: scope),
      _ => presentationDiagnostic(context, [
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Composite control does not match its binding",
        ),
      ]),
    };
  }
}
