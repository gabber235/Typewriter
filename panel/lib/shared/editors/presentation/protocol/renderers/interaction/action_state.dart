part of "../../interaction_renderer.dart";

extension on EditorAction {
  bool enabledIn(PresentationRenderScope scope) =>
      scope.enabled && (this is RealmEditorAction || !scope.readOnly);
}
