import "package:typewriter_panel/typewriter_panel.dart";

import "probes.dart";

/// An adaptive app bar item showing [label] with [icon], or only [icon]
/// when compact, collapsing in [collapseOrder]; it does nothing when pressed
/// unless [onPressed] is given.
AppBarItem textAppBarItem(
  String label,
  IconData icon, {
  required int collapseOrder,
  VoidCallback? onPressed,
}) => AppBarItem.adaptive(
  key: ValueKey(label),
  collapseOrder: collapseOrder,
  child: AppBarControl.text(
    contentBuilder: (context, compact) =>
        AppBarControlContent(compact: compact, icon: Icon(icon), label: label),
    tooltip: label,
    semanticLabel: label,
    onPressed: onPressed ?? () {},
  ),
);

/// An app bar layout [width] wide with a 200 wide primary "Search" box,
/// an adaptive 120 wide "Activity" box collapsing in [activityOrder], and a
/// 50 wide "Mode" box shown only expanded and a 48 wide "Sidebar" box shown
/// only compact, both collapsing in [modeOrder].
final class SampleAppBarLayout extends StatelessWidget {
  const SampleAppBarLayout(
    this.width, {
    this.activityOrder = 1,
    this.modeOrder = 2,
    super.key,
  });

  final double width;
  final int activityOrder;
  final int modeOrder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 48,
      child: CustomAppBarLayout(
        spacing: 8,
        navigation: const SizedBox(width: 100, height: 20),
        primary: AppBarItem.adaptive(
          key: const ValueKey("search"),
          collapseOrder: 0,
          child: LabeledBox("Search", width: 200, height: 40),
        ),
        actions: [
          AppBarItem.adaptive(
            key: const ValueKey("activity"),
            collapseOrder: activityOrder,
            child: LabeledBox("Activity", width: 120, height: 40),
          ),
          AppBarItem.expandedOnly(
            key: const ValueKey("mode"),
            collapseOrder: modeOrder,
            child: LabeledBox("Mode", width: 50, height: 40),
          ),
          AppBarItem.compactOnly(
            key: const ValueKey("sidebar"),
            collapseOrder: modeOrder,
            child: LabeledBox("Sidebar", width: 48, height: 40),
          ),
        ],
      ),
    );
  }
}

/// Lays out [child] twice in one pass: first loosely, as a toolbar measures
/// its controls, then tight at [width] and 48 high, as it then allocates
/// them; a layout that keeps state across the passes shows it here.
class MeasureThenAllocate extends SingleChildRenderObjectWidget {
  const MeasureThenAllocate({
    required this.width,
    required super.child,
    super.key,
  });
  final double width;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderMeasureThenAllocate(width);
  @override
  void updateRenderObject(
    BuildContext context,
    RenderMeasureThenAllocate renderObject,
  ) {
    renderObject
      ..width = width
      ..markNeedsLayout();
  }
}

/// The render object of [MeasureThenAllocate].
class RenderMeasureThenAllocate extends RenderProxyBox {
  RenderMeasureThenAllocate(this.width);
  double width;
  @override
  void performLayout() {
    child!.layout(const BoxConstraints(maxHeight: 48), parentUsesSize: true);
    child!.layout(BoxConstraints.tight(Size(width, 48)), parentUsesSize: true);
    size = constraints.constrain(child!.size);
  }
}
