import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/drivers/component_driver.dart";

/// A box a layout test places and finds by [label].
///
/// It holds [child], or is empty, at the size given; [onTap] makes the whole
/// box answer taps, so a test sees where the box takes input.
final class LabeledBox extends StatelessWidget {
  /// A box named [label] of [width] by [height] around [child].
  const LabeledBox(
    this.label, {
    this.width,
    this.height,
    this.onTap,
    this.child,
    super.key,
  });

  /// The semantics label the box carries.
  final String label;

  /// The box width; null takes the width its parent allows.
  final double? width;

  /// The box height; null takes the height its parent allows.
  final double? height;

  /// Called when the box is tapped anywhere.
  final VoidCallback? onTap;

  /// What the box holds.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final box = SizedBox(width: width, height: height, child: child);
    return Semantics(
      container: true,
      label: label,
      child: onTap == null
          ? box
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: box,
            ),
    );
  }
}

/// A 200 wide text field the user reads as [label].
final class LabeledTextField extends StatelessWidget {
  const LabeledTextField(this.label, {super.key});

  /// The label the field shows and assistive technology reads.
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: TextField(decoration: InputDecoration(labelText: label)),
    );
  }
}

/// Where labeled parts of a component are on screen.
extension LabeledGeometry on ComponentDriver {
  /// The screen rectangle of the widget whose semantics carry [label].
  Rect boundsOf(String label) => tester.getRect(labeled(label));

  /// How far the top left of [label] lies from the top left of [outer].
  Offset positionIn(String label, String outer) =>
      boundsOf(label).topLeft - boundsOf(outer).topLeft;

  /// The [LabeledBox] named [label], found even while it is invisible and
  /// so absent from semantics.
  Finder box(String label) => this.within(
    find.byWidgetPredicate(
      (widget) => widget is LabeledBox && widget.label == label,
    ),
  );

  /// How opaque the [LabeledBox] named [label] is drawn: the opacity of the
  /// nearest fade or opacity around it, or 1 when none is.
  double opacityOf(String label) {
    final target = box(label);
    expect(target, findsOneWidget);
    for (final type in [
      SliverFadeTransition,
      SliverOpacity,
      FadeTransition,
      Opacity,
    ]) {
      final around = find.ancestor(of: target, matching: find.byType(type));
      if (around.evaluate().isEmpty) continue;
      return switch (tester.widget(around.first)) {
        SliverFadeTransition(:final opacity) => opacity.value,
        SliverOpacity(:final opacity) => opacity,
        FadeTransition(:final opacity) => opacity.value,
        Opacity(:final opacity) => opacity,
        _ => 1,
      };
    }
    return 1;
  }

  /// Whether this component reads [part] to assistive technology inside any
  /// label; a button, for one, merges its icon and text into one label.
  bool says(String part) => this
      .within(find.bySemanticsLabel(RegExp(RegExp.escape(part))))
      .evaluate()
      .isNotEmpty;

  /// Whether assistive technology reads [text] whole, as the label or the
  /// value of a node, the way a sighted user reads it.
  bool reads(String text) => find.semantics
      .byPredicate((node) => node.label == text || node.value == text)
      .evaluate()
      .isNotEmpty;

  /// The scroll position of the one scrollable in this component.
  ScrollPosition get scrollPosition => tester
      .state<ScrollableState>(this.within(find.byType(Scrollable)))
      .position;
}

/// Dragging parts of a component with the pointer.
extension Dragging on ComponentDriver {
  /// Drags [target] by [offset] and lets the panel react.
  Future<void> dragBy(Finder target, Offset offset) async {
    await tester.drag(target, offset);
    await settle();
  }
}

/// An 800 by 600 viewport labeled "Viewport" scrolling, in [reverse] when
/// asked, a centered group of [slivers] followed by the [trailing] slivers.
final class CenteredScrollStage extends StatelessWidget {
  /// A stage centering [slivers] before [trailing].
  const CenteredScrollStage({
    required this.slivers,
    this.trailing = const [],
    this.reverse = false,
    super.key,
  });

  /// The slivers the group centers.
  final List<Widget> slivers;

  /// The slivers after the centered group.
  final List<Widget> trailing;

  /// Whether the viewport scrolls in reverse.
  final bool reverse;

  @override
  Widget build(BuildContext context) => LabeledBox(
    "Viewport",
    width: 800,
    height: 600,
    child: CustomScrollView(
      reverse: reverse,
      slivers: [
        CenteredSliverMainAxisGroup(slivers: slivers),
        ...trailing,
      ],
    ),
  );
}
