import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A join code hidden by [BlurReveal] until the pointer rests on it, the way
/// [SecretField] hides what it generated.
@widgetbook.UseCase(name: "Default", type: BlurReveal)
Widget blurRevealUseCase(BuildContext context) {
  return const Story(
    [],
    at: PanelLocation.component(
      BlurReveal(child: Text("$joinCodeUrlPrefix q7Lm2xKe9Rz4")),
    ),
  );
}
