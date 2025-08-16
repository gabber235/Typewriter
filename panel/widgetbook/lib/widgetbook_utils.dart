import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";

extension KnobsBuilderX on KnobsBuilder {
  DisplayState displayState() => object.dropdown(
        label: "Display State",
        options: DisplayState.values,
        labelBuilder: (value) => value.name.formatted,
        initialOption: DisplayState.fewItems,
      );

  Outcome outcome() => object.segmented(
        label: "Outcome",
        options: Outcome.values,
        labelBuilder: (value) => value.name.formatted,
        initialOption: Outcome.success,
      );
}
