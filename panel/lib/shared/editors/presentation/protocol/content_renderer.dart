import "package:flutter/material.dart";
import "package:flutter_markdown_plus/flutter_markdown_plus.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "renderers/content/badge_renderer.dart";
part "renderers/content/icon_renderer.dart";
part "renderers/content/image_renderer.dart";
part "renderers/content/markdown_renderer.dart";
part "renderers/content/progress_renderer.dart";
part "renderers/content/text_renderer.dart";

extension ContentElementRendering on PresentationElement {
  Widget render(BuildContext context, PresentationRenderScope scope) =>
      switch (this) {
        TextElement() => (this as TextElement).render(scope),
        MarkdownElement() => (this as MarkdownElement).render(scope),
        IconElement() => (this as IconElement).render(context, scope),
        ImageElement() => (this as ImageElement).render(context, scope),
        BadgeElement() => (this as BadgeElement).render(context, scope),
        ProgressElement() => (this as ProgressElement).render(context, scope),
        _ => const SizedBox.shrink(),
      };
}
