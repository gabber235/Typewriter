part of "../../layout_renderer.dart";

extension WrapElementRendering on WrapElement {
  Widget render(PresentationRenderScope scope) => LayoutBuilder(
    builder: (context, constraints) => Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: mainAxisAlignment.wrapAlignment,
      crossAxisAlignment: crossAxisAlignment.wrapCrossAlignment,
      children: [
        for (final child in children.renderChildren(scope))
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
            child: child,
          ),
      ],
    ),
  );
}
