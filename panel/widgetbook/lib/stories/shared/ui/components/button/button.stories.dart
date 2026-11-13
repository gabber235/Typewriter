import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/shared/ui/components/button/action_outcome.dart";
import "package:widgetbook_workspace/support/story.dart";

/// Every face of [Button] side by side; pressing one runs an action that
/// ends the way the Outcome knob says, so default, hover, pressed, busy,
/// unavailable and failed can be clicked through.
@widgetbook.UseCase(name: "Default", type: Button)
Widget buttonUseCase(BuildContext context) {
  final outcome = context.knobs.actionOutcome();
  final enabled = context.knobs.boolean(label: "Enabled", initialValue: true);
  final onPressed = enabled ? outcome.run : null;
  return Story(
    const [],
    at: PanelLocation.component(
      Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          Button(
            face: ButtonFace.filled,
            label: "Publish",
            busyLabel: "Publishing",
            onPressed: onPressed,
          ),
          Button(
            face: ButtonFace.filled,
            icon: const Icon(Icons.add),
            label: "Create",
            busyLabel: "Creating",
            onPressed: onPressed,
          ),
          Button(
            face: ButtonFace.outlined,
            label: "Duplicate",
            busyLabel: "Duplicating",
            onPressed: onPressed,
          ),
          Button(label: "Retry", busyLabel: "Retrying", onPressed: onPressed),
          Button(
            face: ButtonFace.icon,
            icon: const Icon(Icons.refresh),
            label: "Refresh",
            tooltip: "Refresh",
            onPressed: onPressed,
          ),
          Button(
            face: ButtonFace.floating,
            icon: const Icon(Icons.add),
            label: "New page",
            busyLabel: "Creating",
            onPressed: onPressed,
          ),
        ],
      ),
    ),
  );
}

/// A [MotionLabel] whose word can be changed and set rippling.
@widgetbook.UseCase(name: "Default", type: MotionLabel)
Widget motionLabelUseCase(BuildContext context) {
  final text = context.knobs.object.dropdown(
    label: "Text",
    options: const ["Publish", "Publishing", "Published"],
  );
  final rippling = context.knobs.boolean(label: "Rippling");
  return Story(
    const [],
    at: PanelLocation.component(MotionLabel(text, rippling: rippling)),
  );
}

/// A sample control that jams each time Fail is pressed.
@widgetbook.UseCase(name: "Default", type: Jam)
Widget jamUseCase(BuildContext context) {
  return HookBuilder(
    builder: (context) {
      final failures = useState(0);
      return Story(
        const [],
        at: PanelLocation.component(
          Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              Jam(
                failures: failures.value,
                child: const ButtonContent(
                  face: ButtonFace.filled,
                  unavailable: false,
                  label: Text("Publish"),
                ),
              ),
              Button(label: "Fail", onPressed: () => failures.value++),
            ],
          ),
        ),
      );
    },
  );
}

/// Every face splashing from where it is pressed: hold to keep the splash,
/// let go inside to act, slide off or press Escape to cancel. Filled and
/// danger faces splash light, the rest in the brand colour.
@widgetbook.UseCase(name: "Press splash", type: PressInk)
Widget pressSplashUseCase(BuildContext context) {
  return Story(
    const [],
    at: PanelLocation.component(
      Builder(
        builder: (context) => Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            Button(label: "Copy", autofocus: true, onPressed: () {}),
            Button(face: ButtonFace.outlined, label: "Open", onPressed: () {}),
            Button(face: ButtonFace.filled, label: "Publish", onPressed: () {}),
            Button(
              face: ButtonFace.filled,
              color: context.colors.danger,
              label: "Delete",
              onPressed: () {},
            ),
          ],
        ),
      ),
    ),
  );
}
