import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/support/ui/probes.dart";

/// A 300 by 300 stage whose [children] stack under one stagger scope that
/// starts an entrance every 100 milliseconds, each running 200 milliseconds
/// linearly without sliding, launching for at most two seconds.
final class StaggerStage extends StatelessWidget {
  /// A stage stacking [children].
  const StaggerStage({required this.children, super.key});

  /// The stacked children, usually [Positioned] entrances.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 300,
    height: 300,
    child: StaggerScope(
      duration: const Duration(milliseconds: 200),
      interval: const Duration(milliseconds: 100),
      maxLaunchDuration: const Duration(seconds: 2),
      curve: Curves.linear,
      slideOffset: 0,
      child: Stack(children: children),
    ),
  );
}

/// A 40 by 20 box named [label] that enters with its stagger scope.
final class EnteringBox extends StatelessWidget {
  /// The entering box [label].
  const EnteringBox(this.label, {super.key});

  /// The label a test finds the box by.
  final String label;

  @override
  Widget build(BuildContext context) =>
      StaggerEntrance(child: LabeledBox(label, width: 40, height: 20));
}

/// A sliver holding a 40 by 20 box named [label] that enters with its
/// sliver stagger scope.
final class EnteringSliverBox extends StatelessWidget {
  /// The entering sliver box [label].
  const EnteringSliverBox(this.label, {super.key});

  /// The label a test finds the box by.
  final String label;

  @override
  Widget build(BuildContext context) => SliverStaggerEntrance(
    sliver: SliverToBoxAdapter(child: LabeledBox(label, width: 40, height: 20)),
  );
}
