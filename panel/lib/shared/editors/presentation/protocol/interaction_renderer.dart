import "package:flutter/material.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "renderers/interaction/action_state.dart";
part "renderers/interaction/button_renderer.dart";
part "renderers/interaction/icon_button_renderer.dart";
part "renderers/interaction/menu_renderer.dart";
part "renderers/interaction/tooltip_renderer.dart";

extension InteractionElementRendering on PresentationElement {
  Widget render(BuildContext context, PresentationRenderScope scope) =>
      switch (this) {
        ButtonElement() => (this as ButtonElement).render(scope),
        IconButtonElement() => (this as IconButtonElement).render(
          context,
          scope,
        ),
        MenuElement() => (this as MenuElement).render(scope),
        TooltipElement() => (this as TooltipElement).render(scope),
        _ => const SizedBox.shrink(),
      };
}
