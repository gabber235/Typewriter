import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

Widget testGraphDragScope(WidgetTester tester, {required Widget child}) {
  return HookBuilder(
    builder: (context) {
      final controller = useGraphInteractionController();
      return GraphDrag(
        controller: controller,
        containsGlobalPosition: (position) =>
            tester.getRect(find.byType(GraphDrag)).contains(position),
        child: child,
      );
    },
  );
}

class GraphDragStateProbe extends StatelessWidget {
  const GraphDragStateProbe({
    required this.sink,
    required this.child,
    super.key,
  });
  final ValueNotifier<bool> sink;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = GraphDrag.maybeOf(context);
    if (scope == null) return child;
    return ValueListenableBuilder<GraphDragSession?>(
      valueListenable: scope.controller.dragState,
      builder: (_, session, _) {
        final inside = session?.inside ?? false;
        if (sink.value != inside) sink.value = inside;
        return child;
      },
    );
  }
}
