import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";

extension KnobsBuilderX on KnobsBuilder {
  DisplayState displayState({
    String label = "Display State",
    DisplayState initialOption = DisplayState.fewItems,
  }) => object.dropdown(
    label: label,
    options: DisplayState.values,
    labelBuilder: (value) => value.name.formatted,
    initialOption: initialOption,
  );

  Outcome outcome() => object.segmented(
    label: "Outcome",
    options: Outcome.values,
    labelBuilder: (value) => value.name.formatted,
    initialOption: Outcome.success,
  );
}
