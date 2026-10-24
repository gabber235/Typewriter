import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Inherited appearance", type: Surface)
Widget surfaceUseCase(BuildContext context) => const FakeApp(
  child: Center(
    child: ColoredBox(
      color: Color(0xff3366cc),
      child: Surface(
        color: Color(0xff3366cc),
        foreground: Colors.white,
        child: Padding(padding: EdgeInsets.all(24), child: _SurfaceContent()),
      ),
    ),
  ),
);

@widgetbook.UseCase(name: "Animated contrast", type: SurfaceContainer)
Widget surfaceContainerUseCase(BuildContext context) =>
    const SurfaceTransitionStory();

class SurfaceTransitionStory extends HookWidget {
  const SurfaceTransitionStory({super.key});

  @override
  Widget build(BuildContext context) {
    final light = useState(false);
    return FakeApp(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SurfaceContainer(
              duration: const Duration(milliseconds: 800),
              width: 360,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: light.value
                    ? const Color(0xffffdd66)
                    : const Color(0xff173466),
                borderRadius: BorderRadius.circular(18),
              ),
              foregroundFor: (context, displayed) => displayed.on(context),
              child: const _SurfaceContent(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => light.value = !light.value,
              child: const Text("Toggle surface"),
            ),
          ],
        ),
      ),
    );
  }
}

@widgetbook.UseCase(
  name: "Owned interaction",
  type: PresentationInteractionScope,
)
Widget presentationInteractionUseCase(BuildContext context) =>
    const SurfaceInteractionStory();

class SurfaceInteractionStory extends HookWidget {
  const SurfaceInteractionStory({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = useState(false);
    final controller = useWidgetStatesController();
    useListenable(controller);
    final interaction = PresentationInteraction.fromWidgetStates(
      controller.value,
    ).copyWith(selected: selected.value);
    return FakeApp(
      child: Center(
        child: PresentationInteractionScope(
          value: interaction,
          child: SurfaceContainer(
            duration: const Duration(milliseconds: 100),
            width: 360,
            decoration: BoxDecoration(
              color: selected.value
                  ? const Color(0xffffdd66)
                  : const Color(0xff173466),
              border: interaction.focused
                  ? Border.all(color: Colors.orange, width: 3)
                  : null,
              borderRadius: BorderRadius.circular(18),
            ),
            foregroundFor: (context, displayed) => displayed.on(context),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                statesController: controller,
                borderRadius: BorderRadius.circular(18),
                onTap: () => selected.value = !selected.value,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _SurfaceContent(),
                      const SizedBox(height: 12),
                      Text(
                        selected.value ? "Selected" : "Press Enter to select",
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SurfaceContent extends StatelessWidget {
  const _SurfaceContent();
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.label),
          const SizedBox(width: 12),
          Text("Adventure", style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        "Tag icon and title share the surface foreground",
        style: TextStyle(color: Surface.secondaryForegroundOf(context)),
      ),
      const SizedBox(height: 8),
      const Text(
        "Explicit semantic accent",
        style: TextStyle(color: Colors.deepOrange),
      ),
    ],
  );
}
