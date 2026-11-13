import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A counter button inside [ExcludeInteraction]: while Excluding, clicks,
/// Tab and screen readers pass it by, yet its count stays, since the button
/// stays mounted.
@widgetbook.UseCase(name: "Default", type: ExcludeInteraction)
Widget excludeInteractionUseCase(BuildContext context) {
  final excluding = context.knobs.boolean(label: "Excluding");
  return Story(
    const [],
    at: PanelLocation.component(
      HookBuilder(
        builder: (context) {
          final count = useState(0);
          return Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              Button(label: "Before", onPressed: () {}),
              ExcludeInteraction(
                excluding: excluding,
                child: Button(
                  face: ButtonFace.outlined,
                  label: "Pressed ${count.value} times",
                  onPressed: () => count.value++,
                ),
              ),
              Button(label: "After", onPressed: () {}),
            ],
          );
        },
      ),
    ),
  );
}
