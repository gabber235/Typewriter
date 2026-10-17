import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Changing status", type: AnimatedStatusContent)
Widget animatedStatusContentUseCase(BuildContext context) =>
    AnimatedStatusContentStory(
      width: context.knobs.double.slider(
        label: "Allocated width",
        initialValue: 220,
        min: 48,
        max: 320,
      ),
      reducedMotion: context.knobs.boolean(label: "Reduced motion"),
    );

/// Exercises status decoration inside the same persistent button.
class AnimatedStatusContentStory extends HookWidget {
  const AnimatedStatusContentStory({
    this.width = 220,
    this.reducedMotion = false,
    super.key,
  });
  final double width;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final step = useState(0);
    final label = switch (step.value % 4) {
      0 => null,
      1 => "Checking",
      2 => "1 issue",
      _ => "12 issues",
    };
    final icon = switch (step.value % 4) {
      0 => Icons.inbox_outlined,
      1 => Icons.sync,
      _ => Icons.error_outline,
    };
    return FakeApp(
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: reducedMotion),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: width,
                  height: 48,
                  child: AppBarControl.filled(
                    contentBuilder: (context, compact) => AnimatedStatusContent(
                      compact: compact,
                      icon: Icon(icon, key: ValueKey(icon), size: 18),
                      label: label,
                    ),
                    tooltip: "Advance status",
                    semanticLabel: label ?? "Inbox",
                    onPressed: () => step.value++,
                  ),
                ),
                TextButton(
                  onPressed: () => step.value++,
                  child: const Text("Next status"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
