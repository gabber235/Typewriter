part of "../../interaction_renderer.dart";

extension MenuElementRendering on MenuElement {
  Widget render(PresentationRenderScope scope) {
    final resolvedLabel = label == null ? null : scope.expressionText(label!);
    return ContextMenuRegion(
      enableGestures: false,
      items: [
        for (final item in items)
          MenuItem(
            label: scope.expressionText(item.label),
            onPressed: item.action.enabledIn(scope)
                ? () => scope.invoke(item.action)
                : null,
          ),
      ],
      builder: (context, controller, child) => resolvedLabel == null
          ? IconButton(
              tooltip: "Open menu",
              onPressed: ContextMenuRegion.onPress(controller),
              icon: const Icones(Fa6Solid.ellipsis_vertical),
            )
          : TextButton(
              onPressed: ContextMenuRegion.onPress(controller),
              child: Text(resolvedLabel),
            ),
    );
  }
}
