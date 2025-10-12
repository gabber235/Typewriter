import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/widgets/generic/components/drag_handle.dart";

import "../../../test_utils.dart";

void main() {

  group("DragHandle", () {
    testWidgets(
        "horizontal increases size when dragging right (default resolver)",
        (tester) async {
      final harnessKey = GlobalKey<_DragHarnessState>();

      await tester.pumpTestApp(
        child: Center(
          child: SizedBox(
            width: 800,
            height: 300,
            child: DragHarness(
              key: harnessKey,
              axis: Axis.horizontal,
              initialSize: 300,
              minSize: 150,
              maxSize: 700,
              enabled: true,
            ),
          ),
        ),
      );

      final start = harnessKey.currentState!.size;
      expect(start, 300);

      final handle = find.byKey(const Key("drag_handle"));
      expect(handle, findsOneWidget);

      await tester.drag(handle, const Offset(80, 0));
      await tester.pumpAndSettle();

      final end = harnessKey.currentState!.size;
      expect(end, greaterThan(start));
      expect(end, 380);
    });

    testWidgets("horizontal custom resolver inverts delta", (tester) async {
      final harnessKey = GlobalKey<_DragHarnessState>();

      await tester.pumpTestApp(
        child: Center(
          child: SizedBox(
            width: 800,
            height: 300,
            child: DragHarness(
              key: harnessKey,
              axis: Axis.horizontal,
              initialSize: 300,
              minSize: 150,
              maxSize: 700,
              enabled: true,
              resolver: (s, d) => s - d,
            ),
          ),
        ),
      );

      final start = harnessKey.currentState!.size;
      expect(start, 300);

      final handle = find.byKey(const Key("drag_handle"));
      await tester.drag(handle, const Offset(80, 0));
      await tester.pumpAndSettle();

      final end = harnessKey.currentState!.size;
      expect(end, lessThan(start));
      expect(end, 220);
    });

    testWidgets("horizontal clamps to min and max", (tester) async {
      final harnessKey = GlobalKey<_DragHarnessState>();

      await tester.pumpTestApp(
        child: Center(
          child: SizedBox(
            width: 500,
            height: 300,
            child: DragHarness(
              key: harnessKey,
              axis: Axis.horizontal,
              initialSize: 300,
              minSize: 200,
              maxSize: 400,
              enabled: true,
            ),
          ),
        ),
      );

      final handle = find.byKey(const Key("drag_handle"));

      await tester.drag(handle, const Offset(500, 0));
      await tester.pumpAndSettle();
      expect(harnessKey.currentState!.size, 400);

      await tester.drag(handle, const Offset(-1000, 0));
      await tester.pumpAndSettle();
      expect(harnessKey.currentState!.size, 200);
    });

    testWidgets("vertical increases size when dragging down (default resolver)",
        (tester) async {
      final harnessKey = GlobalKey<_DragHarnessState>();

      await tester.pumpTestApp(
        child: Center(
          child: SizedBox(
            width: 600,
            height: 600,
            child: DragHarness(
              key: harnessKey,
              axis: Axis.vertical,
              initialSize: 200,
              minSize: 100,
              maxSize: 500,
              enabled: true,
            ),
          ),
        ),
      );

      final start = harnessKey.currentState!.size;
      expect(start, 200);

      final handle = find.byKey(const Key("drag_handle"));
      await tester.drag(handle, const Offset(0, 60));
      await tester.pumpAndSettle();

      final end = harnessKey.currentState!.size;
      expect(end, greaterThan(start));
      expect(end, 260);
    });

    testWidgets("disabled handle does not change size on drag", (tester) async {
      final harnessKey = GlobalKey<_DragHarnessState>();

      await tester.pumpTestApp(
        child: Center(
          child: SizedBox(
            width: 800,
            height: 300,
            child: DragHarness(
              key: harnessKey,
              axis: Axis.horizontal,
              initialSize: 320,
              minSize: 200,
              maxSize: 600,
              enabled: false,
            ),
          ),
        ),
      );

      final start = harnessKey.currentState!.size;
      expect(start, 320);

      final handle = find.byKey(const Key("drag_handle"));
      expect(handle, findsOneWidget);

      expect(tester.renderObject<RenderBox>(handle).size.width, equals(0));
    });
  });
}

class DragHarness extends StatefulWidget {
  const DragHarness({
    required this.axis,
    required this.initialSize,
    required this.minSize,
    required this.maxSize,
    required this.enabled,
    super.key,
    this.resolver,
  });

  final Axis axis;
  final double initialSize;
  final double minSize;
  final double maxSize;
  final bool enabled;
  final SizeResolver? resolver;

  @override
  State<DragHarness> createState() => _DragHarnessState();
}

class _DragHarnessState extends State<DragHarness> {
  late double size;

  @override
  void initState() {
    super.initState();
    size = widget.initialSize;
  }

  @override
  Widget build(BuildContext context) {
    final handle = DragHandle(
      key: const Key("drag_handle"),
      axis: widget.axis,
      enabled: widget.enabled,
      minSize: widget.minSize,
      maxSize: widget.maxSize,
      getSize: () => size,
      onSizeChange: (v) => setState(() => size = v),
      sizeResolver: widget.resolver,
      // Use small animation to keep tests snappy.
      animationDuration: const Duration(milliseconds: 100),
    );

    if (widget.axis == Axis.horizontal) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(color: Colors.blueGrey.shade100),
          ),
          handle,
          AnimatedContainer(
            duration: const Duration(milliseconds: 50),
            curve: Curves.linear,
            width: size,
            color: Colors.blueGrey.shade200,
            child: const SizedBox.expand(),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(color: Colors.blueGrey.shade100),
        ),
        handle,
        AnimatedContainer(
          duration: const Duration(milliseconds: 50),
          curve: Curves.linear,
          height: size,
          color: Colors.blueGrey.shade200,
          child: const SizedBox.expand(),
        ),
      ],
    );
  }
}
