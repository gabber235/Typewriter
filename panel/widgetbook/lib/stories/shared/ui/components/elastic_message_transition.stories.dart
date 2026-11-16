import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// One frame of the [ElasticMessageTransition] an [ElasticMessageSwitcher]
/// plays: drag Progress from 0 to 1 to see the message drop in from above
/// and fade in.
@widgetbook.UseCase(name: "Default", type: ElasticMessageTransition)
Widget elasticMessageTransitionUseCase(BuildContext context) {
  return Story(
    const [],
    at: PanelLocation.component(
      ElasticMessageTransition(
        animation: context.knobs.fraction("Progress"),
        child: const Text("A name is required."),
      ),
    ),
  );
}
