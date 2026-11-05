import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/shared/selectables/operations/operation_story.dart";

@widgetbook.UseCase(name: "Default", type: UnbindOperationButton)
Widget unbindOperationUseCase(BuildContext context) =>
    operationStory(context, (run) => UnbindSelectionCapability(onUnbind: run));
