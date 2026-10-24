import "package:typewriter_panel/typewriter_panel.dart";

/// Provides the operation source for a subtree of selectable UI.
///
/// The app shell installs its source above route content. Inspectors, context
/// menus and shortcuts ask this source which operations a selection offers.
class SelectionOperationsRoot extends InheritedWidget {
  const SelectionOperationsRoot({
    required this.source,
    required super.child,
    super.key,
  });

  /// Where descendants get their operations.
  final SelectionOperationSource source;

  static SelectionOperationSource of(BuildContext context) {
    final root = context
        .dependOnInheritedWidgetOfExactType<SelectionOperationsRoot>();
    assert(root != null, () {
      throw FlutterError("No SelectionOperationsRoot found in context");
    }());
    return root!.source;
  }

  @override
  bool updateShouldNotify(SelectionOperationsRoot oldWidget) =>
      source != oldWidget.source;
}
