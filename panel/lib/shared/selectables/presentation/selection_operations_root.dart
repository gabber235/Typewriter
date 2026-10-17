import "package:typewriter_panel/typewriter_panel.dart";

/// Provides the operation registry for a subtree of selectable UI.
///
/// The app shell installs generic operations above route content. Inspectors,
/// context menus and shortcuts use this list for generic selectables. Realm
/// authoring resources instead project their available resource operations.
class SelectionOperationsRoot extends InheritedWidget {
  const SelectionOperationsRoot({
    required this.operations,
    required super.child,
    super.key,
  });

  /// Operations available to descendants in their declared order.
  final List<SelectionOperation> operations;

  static List<SelectionOperation> of(BuildContext context) {
    final root = context
        .dependOnInheritedWidgetOfExactType<SelectionOperationsRoot>();
    assert(root != null, () {
      throw FlutterError("No SelectionOperationsRoot found in context");
    }());
    return root!.operations;
  }

  @override
  bool updateShouldNotify(SelectionOperationsRoot oldWidget) =>
      operations != oldWidget.operations;
}
