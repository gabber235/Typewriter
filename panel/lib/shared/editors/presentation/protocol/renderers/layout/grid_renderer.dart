part of "../../layout_renderer.dart";

extension GridElementRendering on GridElement {
  Widget render(PresentationRenderScope scope) => LayoutBuilder(
    builder: (context, constraints) {
      final gaps = horizontalSpacing * (columns - 1);
      final width = (constraints.maxWidth - gaps) / columns;
      return Wrap(
        spacing: horizontalSpacing,
        runSpacing: verticalSpacing,
        children: [
          for (final child in children)
            SizedBox(
              width: width,
              child: PresentationNodeRenderer(node: child, scope: scope),
            ),
        ],
      );
    },
  );
}
