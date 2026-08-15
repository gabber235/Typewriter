import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "renderers/input/search_input_renderer.dart";

extension InputElementRendering on PresentationElement {
  Widget render(BuildContext context, PresentationRenderScope scope) =>
      switch (this) {
        TextInputElement() || SelectInputElement() || SliderInputElement() =>
          ScalarInputRendering(this).render(context, scope),
        NumericInputElement() || ToggleInputElement() || SimpleInputElement() =>
          SimpleInputRendering(this).render(context, scope),
        ListInputElement() || MapInputElement() || RecordInputElement() =>
          CompositeInputRendering(this).render(context, scope),
        PolymorphicInputElement() => (this as PolymorphicInputElement).render(
          context,
          scope,
        ),
        SearchInputElement() => (this as SearchInputElement).render(
          context,
          scope,
        ),
        _ => const SizedBox.shrink(),
      };
}
