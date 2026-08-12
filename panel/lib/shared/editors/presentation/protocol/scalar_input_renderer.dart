import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:iconify_flutter_plus/icons/heroicons_solid.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "renderers/input/select_input_renderer.dart";
part "renderers/input/slider_input_renderer.dart";
part "renderers/input/text_input_renderer.dart";

extension ScalarInputRendering on PresentationElement {
  Widget render(
    BuildContext context,
    PresentationRenderScope scope,
  ) => switch (this) {
    TextInputElement() => (this as TextInputElement).render(context, scope),
    SelectInputElement() => (this as SelectInputElement).render(context, scope),
    SliderInputElement() => (this as SliderInputElement).render(context, scope),
    _ => const SizedBox.shrink(),
  };
}
