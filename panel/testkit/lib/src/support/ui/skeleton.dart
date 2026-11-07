import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/support/shown_component.dart";
import "package:typewriter_testkit/src/support/ui/reduced_motion.dart";

/// One skeleton placeholder under its [Shimmer], shown by
/// [ShowSkeleton.showSkeleton].
final class ShownSkeleton {
  ShownSkeleton._(this._tester);

  final WidgetTester _tester;

  /// How far the skeleton gradient is slid across a 100 px wide placeholder.
  double get sweep {
    final shimmer = find.ancestor(
      of: find.byType(ShimmerLoading),
      matching: find.byType(Shimmer),
    );
    final gradient = _tester.state<ShimmerState>(shimmer.first).gradient;
    final slide = gradient.transform!.transform(
      const Rect.fromLTWH(0, 0, 100, 1),
    )!;
    return slide.getTranslation().x;
  }
}

/// Showing a loading placeholder.
extension ShowSkeleton on WidgetTester {
  /// Mounts one [ShimmerLoading] placeholder under a [Shimmer], with
  /// reduced motion when [reducedMotion], and renders its first frame.
  Future<ShownSkeleton> showSkeleton({bool reducedMotion = false}) async {
    Widget skeleton = Shimmer(
      child: ShimmerLoading(
        child: SizedBox(
          width: 100,
          height: 20,
          child: Builder(
            builder: (context) =>
                ColoredBox(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      ),
    );
    if (reducedMotion) skeleton = ReducedMotion(child: skeleton);
    await showComponent(const SizedBox.shrink());
    await showComponent(skeleton, settle: false);
    return ShownSkeleton._(this);
  }
}
