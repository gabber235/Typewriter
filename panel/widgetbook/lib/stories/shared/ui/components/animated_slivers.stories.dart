import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A list section built from [SliverAnimatedContent], [SliverAnimatedGap] and
/// [AnimatedSliverList]: rows enter and leave, and the title, gap and empty
/// state follow whether any row is left.
@widgetbook.UseCase(name: "Animated sections", type: AnimatedSliverList)
Widget animatedSectionsUseCase(BuildContext context) {
  final gap = context.knobs.object.segmented(
    label: "Section spacing",
    options: const [0.0, 24.0, 64.0],
    initialOption: 24.0,
  );
  final reducedMotion = context.knobs.boolean(label: "Reduce motion");
  return Story(
    const [],
    at: PanelLocation.component(
      AnimatedSectionsStory(gap: gap, reducedMotion: reducedMotion),
    ),
  );
}

class AnimatedSectionsStory extends HookWidget {
  const AnimatedSectionsStory({
    this.gap = 24,
    this.reducedMotion = false,
    super.key,
  });
  final double gap;
  final bool reducedMotion;
  @override
  Widget build(BuildContext context) {
    final items = useState(<int>[1, 2]);
    final next = useRef(3);
    return Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
        child: SizedBox(
          width: 440,
          height: 540,
          child: Column(
            children: [
              Row(
                children: [
                  TextButton(
                    onPressed: () =>
                        items.value = [...items.value, next.value++],
                    child: const Text("Add request"),
                  ),
                  TextButton(
                    onPressed: () => items.value = [],
                    child: const Text("Clear"),
                  ),
                ],
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverStaggerScope(
                      sliver: SliverMainAxisGroup(
                        slivers: [
                          SliverAnimatedContent(
                            child: items.value.isEmpty
                                ? null
                                : const SectionTitle(title: "Join requests"),
                          ),
                          SliverAnimatedGap(
                            extent: items.value.isEmpty ? 0 : gap,
                          ),
                          AnimatedSliverList<int>(
                            items: items.value,
                            identity: (item) => item,
                            itemBuilder: (context, item) => ListTile(
                              title: Text("Join request $item"),
                              trailing: IconButton(
                                tooltip: "Remove",
                                onPressed: () => items.value = items.value
                                    .where((value) => value != item)
                                    .toList(),
                                icon: const Icon(Icons.close),
                              ),
                            ),
                          ),
                          SliverAnimatedContent(
                            child: items.value.isEmpty
                                ? const EmptyState(
                                    title: "No join requests",
                                    description: "Requests to join appear here",
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
