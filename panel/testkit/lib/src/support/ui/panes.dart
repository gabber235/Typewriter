import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../shown_component.dart";

/// An 80 by 80 pane [id] placed at [left] and [top] in a stack, holding one
/// button labeled [button]; it does not highlight focus or add a margin.
final class PlacedPane extends StatelessWidget {
  const PlacedPane({
    required this.id,
    required this.button,
    required this.left,
    required this.top,
    this.enabled = true,
    this.primary = false,
    super.key,
  });

  final String id;
  final String button;
  final double left;
  final double top;
  final bool enabled;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      width: 80,
      height: 80,
      child: Pane(
        id: id,
        enabled: enabled,
        primary: primary,
        highlightOnFocus: false,
        margin: EdgeInsets.zero,
        child: ElevatedButton(onPressed: () {}, child: Text(button)),
      ),
    );
  }
}

/// Moving keyboard focus between the panes of one stack.
final class PaneNavigator {
  PaneNavigator._(this._tester);

  final WidgetTester _tester;

  /// A context inside the stack, where pane navigation intents dispatch.
  late BuildContext context;

  /// Moves focus to the next pane in [direction], the way the pane
  /// navigation shortcut does, and lets the focus change land.
  Future<void> navigate(AxisDirection direction) async {
    Actions.invoke(context, NavigatePaneIntent(direction));
    await _tester.pump(const Duration(milliseconds: 1));
    await _tester.pump(const Duration(milliseconds: 1));
  }
}

/// Showing panes in the panel.
extension ShowPanes on WidgetTester {
  /// Shows [panes] in one stack and returns how to navigate between them.
  Future<PaneNavigator> showPanes(List<Widget> panes) async {
    final navigator = PaneNavigator._(this);
    await showComponent(
      Builder(
        builder: (inside) {
          navigator.context = inside;
          return Stack(children: panes);
        },
      ),
    );
    return navigator;
  }
}
