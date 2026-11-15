import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/shared/selectables/operations/operation_story.dart";

@widgetbook.UseCase(name: "Unbind operation", type: UnbindOperation)
Widget unbindOperationUseCase(BuildContext context) => operationStory(
  context,
  (run) => UnbindSelectionCapability(batch: _StoryUnbind(run), target: run),
);

/// Runs the story's action once for each unbinding.
final class _StoryUnbind implements UnbindBatch {
  const _StoryUnbind(this.run);
  final Future<void> Function() run;

  @override
  Future<void> unbind(List<Object> targets) => run();
}
