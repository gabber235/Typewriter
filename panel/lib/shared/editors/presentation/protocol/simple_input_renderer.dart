import "dart:convert";

import "package:duration/duration.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:iconify_flutter_plus/icons/bi.dart";
import "package:iconify_flutter_plus/icons/heroicons_solid.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "renderers/input/bytes_input_renderer.dart";
part "renderers/input/color_input_renderer.dart";
part "renderers/input/date_time_input_renderer.dart";
part "renderers/input/duration_input_renderer.dart";
part "renderers/input/enum_input_renderer.dart";
part "renderers/input/named_input_renderer.dart";
part "renderers/input/numeric_input_renderer.dart";
part "renderers/input/simple_input_support.dart";
part "renderers/input/toggle_input_renderer.dart";

extension SimpleInputRendering on PresentationElement {
  Widget render(
    BuildContext context,
    PresentationRenderScope scope,
  ) => switch (this) {
    NumericInputElement() => (this as NumericInputElement).render(
      context,
      scope,
    ),
    ToggleInputElement() => (this as ToggleInputElement).render(context, scope),
    DateTimeInputElement() => (this as DateTimeInputElement).render(
      context,
      scope,
    ),
    DurationInputElement() => (this as DurationInputElement).render(
      context,
      scope,
    ),
    BytesInputElement() => (this as BytesInputElement).render(context, scope),
    EnumInputElement() => (this as EnumInputElement).render(context, scope),
    ColorInputElement() => (this as ColorInputElement).render(context, scope),
    NamedInputElement() => (this as NamedInputElement).render(context, scope),
    _ => const SizedBox.shrink(),
  };
}
