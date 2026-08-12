import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

extension InputElementRendering on PresentationElement {
  Widget render(BuildContext context, PresentationRenderScope scope) =>
      switch (this) {
        TextInputElement() || SelectInputElement() || SliderInputElement() =>
          ScalarInputRendering(this).render(context, scope),
        IconInputElement(:final control) => ScalarInputRendering(
          TextInputElement(control: control, multiline: false),
        ).render(context, scope),
        NumericInputElement() || ToggleInputElement() || SimpleInputElement() =>
          SimpleInputRendering(this).render(context, scope),
        ListInputElement() || MapInputElement() || RecordInputElement() =>
          CompositeInputRendering(this).render(context, scope),
        PolymorphicInputElement() => (this as PolymorphicInputElement).render(
          context,
          scope,
        ),
        _ => const SizedBox.shrink(),
      };
}
