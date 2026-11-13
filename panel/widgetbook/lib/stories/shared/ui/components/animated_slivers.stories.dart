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
  return Story(
    context.knobs.traits("Motion", {
      "Full": const [],
      "Reduced": const [reducedMotion],
    }),
    at: PanelLocation.component(AnimatedSectionsStory(gap: gap)),
  );
}

class AnimatedSectionsStory extends HookWidget {
  const AnimatedSectionsStory({this.gap = 24, super.key});
  final double gap;
  @override
  Widget build(BuildContext context) {
    final items = useState(<int>[1, 2]);
    final next = useRef(3);
    return SizedBox(
      width: 440,
      height: 540,
      child: Column(
        children: [
          Row(
            children: [
              Button(
                label: "Add request",
                onPressed: () => items.value = [...items.value, next.value++],
              ),
              Button(label: "Clear", onPressed: () => items.value = []),
            ],
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverMainAxisGroup(
                  slivers: [
                    SliverAnimatedContent(
                      child: items.value.isEmpty
                          ? null
                          : const SectionTitle(title: "Join requests"),
                    ),
                    SliverAnimatedGap(extent: items.value.isEmpty ? 0 : gap),
                    AnimatedSliverList<int>(
                      items: items.value,
                      identity: (item) => item,
                      itemBuilder: (context, item) => PanelRow(
                        title: Text("Join request $item"),
                        trailing: Button(
                          face: ButtonFace.icon,
                          icon: const Icon(Icons.close),
                          label: "Remove",
                          tooltip: "Remove",
                          onPressed: () => items.value = items.value
                              .where((value) => value != item)
                              .toList(),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The section title and empty state as [SliverAnimatedContent]: add rows
/// and clear them to watch the title leave and the empty state arrive the
/// way rows do.
@widgetbook.UseCase(name: "Shown or not", type: SliverAnimatedContent)
Widget sliverAnimatedContentUseCase(BuildContext context) {
  return Story(
    context.knobs.motion(),
    at: const PanelLocation.component(AnimatedSectionsStory()),
  );
}

/// The gap under the section title as a [SliverAnimatedGap]: it opens with
/// the first row and closes with the last; Section spacing retargets it.
@widgetbook.UseCase(name: "Opening and closing", type: SliverAnimatedGap)
Widget sliverAnimatedGapUseCase(BuildContext context) {
  final gap = context.knobs.object.segmented(
    label: "Section spacing",
    options: const [0.0, 24.0, 64.0],
    initialOption: 64.0,
  );
  return Story(
    context.knobs.motion(),
    at: PanelLocation.component(AnimatedSectionsStory(gap: gap)),
  );
}

/// Two sections apart by a fixed [SliverGap].
@widgetbook.UseCase(name: "Between sections", type: SliverGap)
Widget sliverGapUseCase(BuildContext context) {
  final extent = context.knobs.object.segmented(
    label: "Extent",
    options: const [8.0, 24.0, 64.0],
    initialOption: 24.0,
  );
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: 360,
        height: 320,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SectionTitle(title: "Members")),
            const SliverToBoxAdapter(child: PanelRow(title: Text("Ada"))),
            SliverGap(extent),
            const SliverToBoxAdapter(child: SectionTitle(title: "Join codes")),
            const SliverToBoxAdapter(child: PanelRow(title: Text("Spring"))),
          ],
        ),
      ),
    ),
  );
}
