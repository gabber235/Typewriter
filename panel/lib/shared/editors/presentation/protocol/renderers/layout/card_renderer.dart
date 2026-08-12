part of "../../layout_renderer.dart";

extension CardElementRendering on CardElement {
  Widget render(PresentationRenderScope scope) =>
      _CardRenderer(element: this, scope: scope);
}

class _CardRenderer extends StatelessWidget {
  const _CardRenderer({required this.element, required this.scope});

  final CardElement element;
  final PresentationRenderScope scope;

  @override
  Widget build(BuildContext context) {
    final child = PresentationNodeRenderer(node: element.child, scope: scope);
    final content = element.initiallyExpanded == null
        ? child
        : ExpansionTile(
            initiallyExpanded: element.initiallyExpanded!,
            title: const SizedBox.shrink(),
            children: [child],
          );
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(padding: const EdgeInsets.all(16), child: content),
    );
  }
}
