import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../drivers/panel_driver.dart";
import "../shown_component.dart";

/// A notifier holding [initial] that ends with the current test.
ValueNotifier<T> testNotifier<T>(T initial) {
  final notifier = ValueNotifier(initial);
  addTearDown(notifier.dispose);
  return notifier;
}

/// What a number field reported, with the controller and focus it uses.
final class WatchedNumberField {
  /// The field's text controller.
  final controller = TextEditingController();

  /// The field's focus.
  final focus = FocusNode();

  /// Every value the field reported as changed, in order.
  final edits = <int>[];

  /// Every value the field reported as done, in order.
  final completions = <int>[];

  /// How often the field reported it was cleared.
  int clears = 0;

  /// How often the field reported its input lost focus.
  int blurs = 0;
}

/// Showing a validated whole number field labeled "Amount".
extension ShowNumberField on WidgetTester {
  /// Shows a 400 wide whole number field labeled "Amount" that shows
  /// [value] and reports edits through the callbacks given; a draft that is
  /// not a whole number reads "Enter a whole number".
  Future<PanelDriver> showNumberField({
    required ValueListenable<int?> value,
    required ValueChanged<int> onChanged,
    VoidCallback? onCleared,
    TextEditingController? controller,
    FocusNode? focusNode,
    ValueChanged<int>? onDone,
    VoidCallback? onInputBlur,
  }) => showComponent(
    SizedBox(
      width: 400,
      child: ValueListenableBuilder<int?>(
        valueListenable: value,
        builder: (context, value, _) => ValidatedTextField<int>(
          value: value,
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(labelText: "Amount"),
          serialize: (draft) =>
              int.tryParse(draft) ??
              (throw const FormatException("Enter a whole number")),
          onChanged: onChanged,
          onCleared: onCleared,
          onDone: onDone,
          onInputBlur: onInputBlur,
        ),
      ),
    ),
  );

  /// Shows [showNumberField] over [value] with its own controller and focus,
  /// and returns what it reports.
  Future<WatchedNumberField> showWatchedNumberField(
    ValueListenable<int?> value,
  ) async {
    final field = WatchedNumberField();
    addTearDown(field.controller.dispose);
    addTearDown(field.focus.dispose);
    await showNumberField(
      value: value,
      controller: field.controller,
      focusNode: field.focus,
      onChanged: field.edits.add,
      onCleared: () => field.clears++,
      onDone: field.completions.add,
      onInputBlur: () => field.blurs++,
    );
    return field;
  }
}
