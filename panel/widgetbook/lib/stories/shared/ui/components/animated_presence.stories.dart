import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A bulk bar built with [AnimatedPresence] above a short list: it arrives
/// when shown and squashes shut when hidden, and the rows close the gap.
@widgetbook.UseCase(name: "Shown and hidden", type: AnimatedPresence)
Widget animatedPresenceUseCase(BuildContext context) {
  final shown = context.knobs.boolean(
    label: "Bulk bar shown",
    initialValue: true,
  );
  return Story(
    const [],
    at: PanelLocation.component(AnimatedPresenceStory(shown: shown)),
  );
}

/// The same bar for a user who asked for reduced motion: it lands at once.
@widgetbook.UseCase(name: "Reduced motion", type: AnimatedPresence)
Widget animatedPresenceReducedUseCase(BuildContext context) {
  final shown = context.knobs.boolean(
    label: "Bulk bar shown",
    initialValue: true,
  );
  return Story(const [
    reducedMotion,
  ], at: PanelLocation.component(AnimatedPresenceStory(shown: shown)));
}

class AnimatedPresenceStory extends StatelessWidget {
  const AnimatedPresenceStory({this.shown = true, super.key});

  final bool shown;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedPresence(child: shown ? const Text("2 selected") : null),
          for (final name in const ["Ada", "Grace", "Linus"])
            Padding(
              padding: EdgeInsets.all(context.spacing.space3),
              child: Text(name),
            ),
        ],
      ),
    );
  }
}
