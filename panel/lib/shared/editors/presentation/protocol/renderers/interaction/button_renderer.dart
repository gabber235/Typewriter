part of "../../interaction_renderer.dart";

extension ButtonElementRendering on ButtonElement {
  Widget render(PresentationRenderScope scope) => FilledButton(
    onPressed: action.enabledIn(scope) ? () => scope.invoke(action) : null,
    child: Text(scope.expressionText(label)),
  );
}
