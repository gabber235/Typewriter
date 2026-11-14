import "package:typewriter_panel/typewriter_panel.dart";

/// A block in a list that is shown or not, such as a section heading or a
/// notice. It arrives and leaves the way rows do; a child with a new key or
/// type is a removal plus an insertion.
class SliverAnimatedContent extends StatelessWidget {
  const SliverAnimatedContent({required this.child, super.key});
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSliverList<Widget>(
      items: [?child],
      identity: (child) => child.key ?? child.runtimeType,
      itemBuilder: (context, child) => child,
    );
  }
}

/// Independently composable spacing between scroll sections.
class SliverGap extends StatelessWidget {
  const SliverGap(this.extent, {super.key});
  final double extent;

  @override
  Widget build(BuildContext context) =>
      SliverToBoxAdapter(child: SizedBox(height: extent));
}

/// Spacing that opens with rowIn and closes with listOut beside its rows;
/// a change mid move retargets from the height on screen.
class SliverAnimatedGap extends HookWidget {
  const SliverAnimatedGap({required this.extent, super.key})
    : assert(extent >= 0 && extent < double.infinity);
  final double extent;

  @override
  Widget build(BuildContext context) {
    final previous = usePrevious(extent) ?? extent;
    final opening = extent >= previous;
    // useMotion rebuilds this widget on every tick of the gap.
    final height = useMotion(
      opening ? MotionToken.rowIn : MotionToken.listOut,
      extent,
    ).value;
    return SliverToBoxAdapter(child: SizedBox(height: max(0, height)));
  }
}

/// Animated collection presentation. The feature owns its items and
/// actions; rows load, arrive and leave with the row tokens.
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
    final rows = useAnimatedRows(items: items, identity: identity);
    return SliverAnimatedRows(
      rows: rows,
      itemBuilder: (context, entry) => itemBuilder(context, entry.item),
    );
  }
}
