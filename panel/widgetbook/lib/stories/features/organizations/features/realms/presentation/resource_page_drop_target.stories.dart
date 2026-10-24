import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/features/organizations/features/realms/presentation/resource_operation_drop_target.stories.dart";

@widgetbook.UseCase(
  name: "Move entries to a page",
  type: ResourcePageDropTarget,
)
Widget resourcePageDropTargetUseCase(BuildContext context) =>
    resourceOperationDropTargetExample(
      dropEnabled: context.knobs.boolean(
        label: "Drop target enabled",
        initialValue: true,
      ),
      available: context.knobs.boolean(
        label: "Destination compatible",
        initialValue: true,
      ),
      delayed: context.knobs.boolean(
        label: "Delayed hover check",
        initialValue: false,
      ),
    );
