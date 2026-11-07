import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("an interaction reaches the move table as the widget states it was read from", () {
    for (final states in [
      {WidgetState.hovered},
      {WidgetState.focused},
      {WidgetState.pressed},
      {WidgetState.selected},
      {WidgetState.disabled},
      {WidgetState.selected, WidgetState.hovered},
    ]) {
      expect(
        PresentationInteraction.fromWidgetStates(states).widgetStates,
        states,
      );
    }
  });

  test("states without a widget state carry none", () {
    expect(
      const PresentationInteraction(
        readOnly: true,
        routed: true,
        invalid: true,
      ).widgetStates,
      isEmpty,
    );
  });
}
