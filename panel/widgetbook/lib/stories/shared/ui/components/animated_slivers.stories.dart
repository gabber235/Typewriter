import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Conditional content", type: SliverAnimatedContent)
Widget sliverAnimatedContentUseCase(BuildContext context) =>
    AnimatedSectionsStory(
      reducedMotion: context.knobs.boolean(label: "Reduce motion"),
    );
@widgetbook.UseCase(name: "Collection updates", type: AnimatedSliverList)
Widget animatedSliverListUseCase(BuildContext context) => AnimatedSectionsStory(
  reducedMotion: context.knobs.boolean(label: "Reduce motion"),
);
@widgetbook.UseCase(name: "Composable spacing", type: SliverGap)
Widget sliverGapUseCase(BuildContext context) => AnimatedSectionsStory(
  gap: context.knobs.double.slider(
    label: "Section spacing",
    initialValue: 24,
    min: 0,
    max: 64,
  ),
);

@widgetbook.UseCase(name: "Conditional spacing", type: SliverAnimatedGap)
Widget sliverAnimatedGapUseCase(BuildContext context) => AnimatedSectionsStory(
  reducedMotion: context.knobs.boolean(label: "Reduce motion"),
);

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
    return FakeApp(
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: reducedMotion),
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
                      child: const Text("Add row"),
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
                                  : const SectionTitle(title: "Items"),
                            ),
                            SliverAnimatedGap(
                              extent: items.value.isEmpty ? 0 : gap,
                            ),
                            AnimatedSliverList<int>(
                              items: items.value,
                              identity: (item) => item,
                              itemBuilder: (context, item) => ListTile(
                                title: Text("Item $item"),
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
                                      title: "No items",
                                      description:
                                          "Add a row to see its entrance",
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
      ),
    );
  }
}
