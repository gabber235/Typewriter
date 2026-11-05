import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";
import "package:typewriter_testkit/src/support/shown_component.dart";

/// A nullable value one field edits, starting empty or as a mixed
/// selection; the first change or clear ends the mixed state.
final class NullableFieldOwner<T> {
  /// Starts empty, as a mixed selection when [mixed].
  NullableFieldOwner(this.mixed);

  /// Whether the field still shows a mixed selection.
  bool mixed;

  /// The current value; null while empty.
  T? value;

  /// Every value a change wrote, in order.
  final writes = <T>[];

  /// How often the field was cleared.
  int clears = 0;

  /// Shows the field [build] makes for the current state.
  Future<PanelDriver> pump(
    WidgetTester tester,
    Widget Function(
      T? value,
      bool mixed,
      ValueChanged<T> changed,
      VoidCallback cleared,
    )
    build,
  ) => tester.showComponent(
    StatefulBuilder(
      builder: (_, setState) => build(
        value,
        mixed,
        (next) => setState(() {
          value = next;
          mixed = false;
          writes.add(next);
        }),
        () => setState(() {
          value = null;
          mixed = false;
          clears++;
        }),
      ),
    ),
  );
}

/// Showing the panel's value fields.
extension ShowValueFields on WidgetTester {
  /// Shows a date and time field over a fixed value with microsecond
  /// precision, and returns the panel with a reader of the value the field
  /// last reported.
  Future<(PanelDriver, DateTime Function())> showDateTimeField({
    bool includeDate = true,
    bool enabled = true,
    bool readOnly = false,
    Key? key,
  }) async {
    var value = DateTime.utc(2024, 8, 12, 18, 30, 45, 123, 456);
    final panel = await showComponent(
      StatefulBuilder(
        key: key,
        builder: (context, setState) {
          return SizedBox(
            width: 420,
            child: DateTimePickerField(
              value: value,
              includeDate: includeDate,
              includeTime: true,
              enabled: enabled,
              readOnly: readOnly,
              onChanged: (next) => setState(() => value = next),
            ),
          );
        },
      ),
    );
    return (panel, () => value);
  }

  /// Shows a color field starting at [color], and returns the panel with a
  /// reader of the color the field last reported.
  Future<(PanelDriver, Color Function())> showColorField(
    Color color, {
    required bool includeAlpha,
    bool enabled = true,
    bool readOnly = false,
  }) async {
    var current = color;
    final panel = await showComponent(
      StatefulBuilder(
        builder: (context, setState) => SizedBox(
          width: 420,
          child: ColorPickerField(
            color: current,
            includeAlpha: includeAlpha,
            enabled: enabled,
            readOnly: readOnly,
            onChanged: (next) => setState(() => current = next),
          ),
        ),
      ),
    );
    return (panel, () => current);
  }
}
