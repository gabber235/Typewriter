import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "renderers/layout/card_renderer.dart";
part "renderers/layout/collapsible_renderer.dart";
part "renderers/layout/column_renderer.dart";
part "renderers/layout/divider_renderer.dart";
part "renderers/layout/grid_renderer.dart";
part "renderers/layout/layout_support.dart";
part "renderers/layout/row_renderer.dart";
part "renderers/layout/section_renderer.dart";
part "renderers/layout/spacer_renderer.dart";
part "renderers/layout/stack_renderer.dart";
part "renderers/layout/tabs_renderer.dart";
part "renderers/layout/wrap_renderer.dart";

extension LayoutElementRendering on PresentationElement {
  Widget render(BuildContext context, PresentationRenderScope scope) =>
      switch (this) {
        ColumnElement() => (this as ColumnElement).render(scope),
        RowElement() => (this as RowElement).render(scope),
        WrapElement() => (this as WrapElement).render(scope),
        StackElement() => (this as StackElement).render(scope),
        GridElement() => (this as GridElement).render(scope),
        CardElement() => (this as CardElement).render(scope),
        SectionElement() => (this as SectionElement).render(scope),
        CollapsibleElement() => (this as CollapsibleElement).render(scope),
        TabsElement() => (this as TabsElement).render(scope),
        DividerElement() => (this as DividerElement).render(),
        SpacerElement() => (this as SpacerElement).render(scope),
        _ => const SizedBox.shrink(),
      };
}
