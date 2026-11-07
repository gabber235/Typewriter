import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/pump_panel.dart";
import "package:typewriter_testkit/src/core/stage.dart";
import "package:typewriter_testkit/src/shared/editors/presentation/collection_editor_fixture.dart";
import "package:typewriter_testkit/src/support/ui/reduced_motion.dart";

/// An editor list whose items are text values, each identified by its own
/// text, shown by [ShowCollectionMotion.showCollection].
final class ShownCollection {
  ShownCollection._(this._scenario);

  final CollectionEditorScenario _scenario;

  /// The item texts in the draft, in order.
  List<String> get order => [
    for (final item in _scenario.value.authoredItems!)
      item.value.authoredString!,
  ];

  /// Replaces the items with [labels], the way the authoring document
  /// changing does; the next frame shows it.
  void update(List<String> labels) => _scenario.binding
      .edit(
        label: "Replace the items",
        apply: (edit) => edit.set(
          skir.ValueLocation(
            resource: CollectionEditorScenario.resource,
            path: CollectionEditorScenario.entriesPath,
          ),
          skir.DataValue.createNamed(
            actualType: _scenario.value.authoredActualType!,
            payload: skir.DataValue.createListValue(
              items: [
                for (final label in labels)
                  skir.ListItem(
                    id: skir.ItemId(value: label),
                    value: skir.DataValue.wrapStringValue(label),
                  ),
              ],
            ),
          ),
        ),
      )
      .requireAccepted();

  /// Removes [label] the way another author's change does.
  void removeByOther(String label) => update([...order]..remove(label));
}

/// An editor map of text keys to text values, each row identified by its
/// key, shown by [ShowCollectionMotion.showMap].
final class ShownMap {
  ShownMap._(this._scenario);

  final CollectionEditorScenario _scenario;

  /// Replaces the rows with [rows], the way the authoring document changing
  /// does; the next frame shows it.
  void update(Map<String, String> rows) => _scenario.binding
      .edit(
        label: "Replace the rows",
        apply: (edit) => edit.set(
          skir.ValueLocation(
            resource: CollectionEditorScenario.resource,
            path: CollectionEditorScenario.entriesPath,
          ),
          skir.DataValue.createNamed(
            actualType: _scenario.value.authoredActualType!,
            payload: skir.DataValue.createMapValue(
              rows: [
                for (final MapEntry(:key, :value) in rows.entries)
                  skir.MapRow(
                    id: skir.ItemId(value: key),
                    key: skir.DataValue.wrapStringValue(key),
                    value: skir.DataValue.wrapStringValue(value),
                  ),
              ],
            ),
          ),
        ),
      )
      .requireAccepted();
}

/// A reorder drag held on an item's handle.
final class HandleDrag {
  HandleDrag._(this._tester, this._gesture, this._top);

  final WidgetTester _tester;
  final TestGesture _gesture;

  /// Where the dragged item's text top is now.
  double _top;

  /// Moves the dragged item so its text's top sits at [top] on screen, in
  /// small steps the way a pointer moves.
  Future<void> moveTo(double top) async {
    final distance = top - _top;
    for (var step = 1; step <= 10; step++) {
      await _gesture.moveBy(Offset(0, distance / 10));
      await _tester.pump(const Duration(milliseconds: 16));
    }
    _top = top;
  }

  /// Drops the item.
  Future<void> up() async {
    await _gesture.up();
    await _tester.pump();
  }
}

/// Showing editor collections whose items arrive, leave and move.
extension ShowCollectionMotion on WidgetTester {
  /// Shows an editor list of [labels], reorderable when [allowReorder],
  /// with the service's item moves from [appearance], and with reduced
  /// motion when [reducedMotion]. Returns the list's draft.
  Future<ShownCollection> showCollection(
    List<String> labels, {
    required bool allowReorder,
    bool reducedMotion = false,
    skir.CollectionAppearance? appearance,
  }) async {
    final scenario = CollectionEditorScenario(
      transformLayout: (node) {
        final list =
            (node.element! as skir.PresentationElement_listInputWrapper).value;
        return (node.toMutable()
              ..element = skir.PresentationElement.wrapListInput(
                (list.toMutable()
                      ..allowReorder = allowReorder
                      ..appearance = appearance)
                    .toFrozen(),
              ))
            .toFrozen();
      },
    );
    addTearDown(scenario.dispose);
    final shown = ShownCollection._(scenario)..update(labels);
    await _showScenario(scenario, reducedMotion: reducedMotion);
    return shown;
  }

  /// Shows an editor map of [rows]. Returns the map's draft.
  Future<ShownMap> showMap(Map<String, String> rows) async {
    final scenario = CollectionEditorScenario(
      example: CollectionEditorExample.scalarMap,
    );
    addTearDown(scenario.dispose);
    final shown = ShownMap._(scenario)..update(rows);
    await _showScenario(scenario, reducedMotion: false);
    return shown;
  }

  Future<void> _showScenario(
    CollectionEditorScenario scenario, {
    required bool reducedMotion,
  }) async {
    Widget view = SingleChildScrollView(
      child: SizedBox(
        width: 600,
        child: CollectionEditorScenarioView(scenario: scenario),
      ),
    );
    if (reducedMotion) view = ReducedMotion(child: view);
    await pumpPanel(const [], at: PanelLocation.component(view));
  }

  /// Drags the reorder handle on the row of [label] so the text's top lands
  /// at [to], or by [by], and drops it.
  Future<void> dragHandleOf(String label, {double? to, Offset? by}) async {
    final top = getRect(find.text(label).first).top;
    final drag = await startHandleDrag(label);
    await drag.moveTo(to ?? top + by!.dy);
    await drag.up();
  }

  /// Presses the reorder handle on the row of [label] and starts dragging.
  Future<HandleDrag> startHandleDrag(String label) async {
    final text = getRect(find.text(label).first);
    final center = text.center;
    final handles = find.byWidgetPredicate(
      (widget) =>
          widget is Tooltip &&
          (widget.message?.startsWith("Reorder item") ?? false),
    );
    // The handle in the same row is the nearest one on the vertical axis.
    final handle = handles
        .evaluate()
        .map((element) {
          final box = element.renderObject! as RenderBox;
          return box.localToGlobal(box.size.center(Offset.zero));
        })
        .reduce(
          (a, b) =>
              (a.dy - center.dy).abs() <= (b.dy - center.dy).abs() ? a : b,
        );
    final gesture = await startGesture(handle);
    await pump(const Duration(milliseconds: 16));
    return HandleDrag._(this, gesture, text.top);
  }
}
