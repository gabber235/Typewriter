import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/pump_panel.dart";
import "package:typewriter_testkit/src/core/stage.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";
import "package:typewriter_testkit/src/shared/selectables/selection_fixtures.dart";

/// A surface with gated selection shortcuts, as the search modal and the
/// selector popup mount them: the selectable item [target], read as
/// "Target", beside a text field labeled "Name", offering [operation].
final class GatedShortcutSurface extends StatelessWidget {
  const GatedShortcutSurface({
    required this.target,
    required this.operation,
    super.key,
  });

  final SelectableIdentifier target;
  final SelectionOperation operation;

  @override
  Widget build(BuildContext context) {
    return SelectionOperationsRoot(
      source: RegisteredSelectionOperations([operation]),
      child: GlobalOperationShortcuts(
        child: HookBuilder(
          builder: (context) {
            final focus = useFocusNode();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Selector(
                  selectableId: target,
                  focusNode: focus,
                  builder: (selected, focused, hovered) => const SizedBox(
                    width: 180,
                    height: 60,
                    child: Text("Target"),
                  ),
                ),
                const SizedBox(
                  width: 200,
                  child: EditorTextField(
                    decoration: InputDecoration(labelText: "Name"),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Showing a [GatedShortcutSurface] in the panel.
extension PumpGatedShortcuts on WidgetTester {
  /// Pumps a [GatedShortcutSurface] of [target] whose shortcut operation
  /// records every run.
  Future<({PanelDriver panel, RecordingShortcutOperation operation})>
  pumpGatedShortcuts(SelectableIdentifier target) async {
    final operation = RecordingShortcutOperation();
    final panel = await pumpPanel(
      const [],
      at: PanelLocation.component(
        GatedShortcutSurface(target: target, operation: operation),
      ),
    );
    return (panel: panel, operation: operation);
  }
}
