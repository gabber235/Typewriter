import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/pump_panel.dart";
import "package:typewriter_testkit/src/core/stage.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";

/// Showing one component in the panel and showing it again with new inputs.
extension ShowComponent on WidgetTester {
  static final _shown = Expando<_Shown>();

  /// Shows [child] inside the panel shell.
  ///
  /// The first call pumps the panel; a later call in the same test replaces
  /// the component in place, the way a parent rebuilding it with new inputs
  /// does, so state the component keeps survives. Once the test pumped a
  /// different widget tree, the next call pumps the panel again.
  ///
  /// A replacement settles; with [settle] false it renders only the next
  /// frame, so the test can watch a transition the new inputs start.
  Future<PanelDriver> showComponent(Widget child, {bool settle = true}) async {
    final shown = _shown[this];
    if (shown != null && find.byType(PanelStage).evaluate().isNotEmpty) {
      shown.child.value = child;
      if (settle) {
        await shown.panel.settle();
      } else {
        await pump();
      }
      return shown.panel;
    }
    final current = ValueNotifier(child);
    addTearDown(() {
      _shown[this] = null;
      current.dispose();
    });
    final panel = await pumpPanel(
      const [],
      at: PanelLocation.component(
        ValueListenableBuilder(
          valueListenable: current,
          builder: (context, child, _) => child,
        ),
      ),
    );
    _shown[this] = _Shown(current, panel);
    return panel;
  }

  /// Mounts [child] into a panel that already finished starting, and renders
  /// only its first frame.
  ///
  /// Entrance animations and first frame work then start on a frame the test
  /// drives itself, not while the panel settles its own startup.
  Future<PanelDriver> mountComponent(Widget child) async {
    await showComponent(const SizedBox.shrink());
    return showComponent(child, settle: false);
  }
}

final class _Shown {
  _Shown(this.child, this.panel);

  final ValueNotifier<Widget> child;
  final PanelDriver panel;
}

/// How a flow a test opened ended: whether it completed and with which
/// value.
final class FlowOutcome<T> {
  /// Whether the flow finished, with or without a result.
  bool completed = false;

  /// The value the flow finished with; null when it was cancelled.
  T? result;
}

/// Opening a flow from a button, the way a user starts it.
extension OpenFromButton on WidgetTester {
  /// Shows a button labeled [label] that runs [open], presses it, and returns
  /// the panel with the outcome [open] reports once it finishes.
  Future<(PanelDriver, FlowOutcome<T>)> openFromButton<T>(
    Future<T?> Function(BuildContext context) open, {
    String label = "Open",
  }) async {
    final outcome = FlowOutcome<T>();
    final panel = await showComponent(
      Builder(
        builder: (context) => FilledButton(
          onPressed: () async {
            final result = await open(context);
            outcome
              ..result = result
              ..completed = true;
          },
          child: Text(label),
        ),
      ),
    );
    await panel.tapOn(panel.labeled(label));
    return (panel, outcome);
  }
}
