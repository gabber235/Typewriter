import "package:typewriter_panel/typewriter_panel.dart";

/// Conditional box content that shares a scroll surface with animated rows.
class SliverAnimatedContent extends StatelessWidget {
  const SliverAnimatedContent({required this.child, super.key});
  final Widget? child;

  @override
  Widget build(BuildContext context) =>
      SliverToBoxAdapter(child: ElasticMessageSwitcher(child: child));
}

/// Independently composable spacing between scroll sections.
class SliverGap extends StatelessWidget {
  const SliverGap(this.extent, {super.key});
  final double extent;

  @override
  Widget build(BuildContext context) =>
      SliverToBoxAdapter(child: SizedBox(height: extent));
}

/// Animates spacing independently of section headings and collection contents.
class SliverAnimatedGap extends StatelessWidget {
  const SliverAnimatedGap({required this.extent, super.key})
    : assert(extent >= 0 && extent < double.infinity);
  final double extent;

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
    child: AnimatedContainer(
      height: extent,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 300),
    ),
  );
}

/// Animated collection presentation. The feature owns its items and actions.
class AnimatedSliverList<T> extends HookWidget {
  const AnimatedSliverList({
    required this.items,
    required this.identity,
    required this.itemBuilder,
    super.key,
  });
  final List<T> items;
  final Object Function(T) identity;
  final Widget Function(BuildContext, T) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    Widget row(
      BuildContext context,
      T item,
      Animation<double> animation, {
      bool departing = false,
    }) {
      final child = ExcludeInteraction(
        key: ValueKey(identity(item)),
        excluding: departing,
        child: itemBuilder(context, item),
      );
      return reduced
          ? child
          : ElasticTransition(
              animation: animation,
              child: StaggerEntrance(child: child),
            );
    }

    final collection = useSliverAnimatedList(
      items: items,
      identity: identity,
      insertDuration: reduced
          ? Duration.zero
          : const Duration(milliseconds: 300),
      removeDuration: reduced
          ? Duration.zero
          : const Duration(milliseconds: 180),
      removedItemBuilder: (context, item, animation) =>
          row(context, item, animation, departing: true),
    );
    return SliverAnimatedList(
      key: collection.key,
      initialItemCount: collection.items.length,
      itemBuilder: (context, index, animation) =>
          row(context, collection.items[index], animation),
    );
  }
}
