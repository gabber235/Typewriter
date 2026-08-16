import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "data_renderer.freezed.dart";
part "renderers/data/conditional_renderer.dart";
part "renderers/data/collection_renderer.dart";
part "renderers/data/diagnostic_renderer.dart";
part "renderers/data/repeated_renderer.dart";
part "renderers/data/sequence_renderer.dart";
part "renderers/data/scoped_binding_renderer.dart";
part "renderers/data/typed_field_renderer.dart";

extension DataElementRendering on PresentationElement {
  Widget render(BuildContext context, PresentationRenderScope scope) =>
      switch (this) {
        DiagnosticElement() => (this as DiagnosticElement).render(context),
        TypedFieldElement() => (this as TypedFieldElement).render(scope),
        ConditionalElement() => (this as ConditionalElement).render(
          context,
          scope,
        ),
        RepeatedElement() => (this as RepeatedElement).render(context, scope),
        ScopedBindingElement() => (this as ScopedBindingElement).render(
          context,
          scope,
        ),
        CollectionLookupElement() => (this as CollectionLookupElement).render(
          context,
          scope,
        ),
        CollectionGraphElement() => (this as CollectionGraphElement).render(
          context,
          scope,
        ),
        _ => const SizedBox.shrink(),
      };
}
