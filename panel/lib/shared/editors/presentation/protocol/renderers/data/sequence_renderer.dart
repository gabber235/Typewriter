part of "../../data_renderer.dart";

Widget renderSequence({
  required BuildContext context,
  required SequencePresentation presentation,
  required PresentationRenderScope scope,
  required List<PresentationRenderScope> itemScopes,
}) {
  if (itemScopes.isEmpty) {
    final empty = presentation.empty;
    if (empty == null) return const SizedBox.shrink();
    return _renderSequenceNode(empty, scope);
  }
  final children = <Widget>[];
  final separator = presentation.separator;
  for (final (index, itemScope) in itemScopes.indexed) {
    if (index > 0 && separator != null) {
      children.add(
        KeyedSubtree(
          key: ValueKey("separator.$index"),
          child: _renderSequenceNode(separator, scope),
        ),
      );
    }
    children.add(
      KeyedSubtree(
        key: ValueKey("item.$index"),
        child: _renderSequenceNode(presentation.item, itemScope),
      ),
    );
  }
  return presentation.layout.renderWidgets(context, children);
}

Widget _renderSequenceNode(
  PresentationNode node,
  PresentationRenderScope scope,
) => PresentationNodeRenderer(
  node: node.localizeFailures(
    scope.expressions,
    registry: scope.registry,
    budget: scope.budget,
  ),
  scope: scope,
);
