import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/shared/selectables/operations/operation_story.dart";

@widgetbook.UseCase(name: "Default", type: OpenOperationButton)
Widget openOperationUseCase(BuildContext context) =>
    operationStory(context, (run) => OpenSelectionCapability(onOpen: run));
