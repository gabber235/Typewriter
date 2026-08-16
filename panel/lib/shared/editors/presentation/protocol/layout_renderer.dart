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

extension PresentationChildrenLayoutRendering on PresentationChildrenLayout {
  Widget renderWidgets(BuildContext context, List<Widget> children) =>
      switch (this) {
        PresentationColumnLayout(
          :final spacing,
          :final mainAxisAlignment,
          :final crossAxisAlignment,
        ) =>
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: mainAxisAlignment.mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment.crossAxisAlignment,
            children: children.spaced(spacing, vertical: true),
          ),
        PresentationRowLayout(
          :final spacing,
          :final mainAxisAlignment,
          :final crossAxisAlignment,
        ) =>
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: mainAxisAlignment.mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment.crossAxisAlignment,
            children: children.spaced(spacing),
          ),
        PresentationWrapLayout(
          :final spacing,
          :final runSpacing,
          :final mainAxisAlignment,
          :final crossAxisAlignment,
        ) =>
          Wrap(
            spacing: spacing,
            runSpacing: runSpacing,
            alignment: mainAxisAlignment.wrapAlignment,
            crossAxisAlignment: crossAxisAlignment.wrapCrossAlignment,
            children: children,
          ),
        PresentationGridLayout(
          :final columns,
          :final horizontalSpacing,
          :final verticalSpacing,
        ) =>
          LayoutBuilder(
            builder: (context, constraints) {
              final gaps = horizontalSpacing * (columns - 1);
              final width = (constraints.maxWidth - gaps) / columns;
              return Wrap(
                spacing: horizontalSpacing,
                runSpacing: verticalSpacing,
                children: [
                  for (final child in children)
                    SizedBox(width: width, child: child),
                ],
              );
            },
          ),
        PresentationStackLayout() => Stack(children: children),
      };
}

extension on List<Widget> {
  List<Widget> spaced(double spacing, {bool vertical = false}) {
    if (spacing == 0 || length < 2) return this;
    return [
      for (final (index, child) in indexed) ...[
        if (index > 0)
          SizedBox(
            width: vertical ? 0 : spacing,
            height: vertical ? spacing : 0,
          ),
        child,
      ],
    ];
  }
}
