import "package:flutter/widgets.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class SelectionOperationsRoot extends InheritedWidget {
  const SelectionOperationsRoot({
    required this.operations,
    required super.child,
    super.key,
  });

  final List<SelectionOperation> operations;

  static List<SelectionOperation> of(BuildContext context) {
    final root = context
        .dependOnInheritedWidgetOfExactType<SelectionOperationsRoot>();
    assert(root != null, "No SelectionOperationsRoot found in context");
    return root!.operations;
  }

  @override
  bool updateShouldNotify(SelectionOperationsRoot oldWidget) =>
      operations != oldWidget.operations;
}
