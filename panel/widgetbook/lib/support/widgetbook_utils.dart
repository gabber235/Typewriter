import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_workspace/data/data.dart";

extension KnobsBuilderX on KnobsBuilder {
  RealmConnectionState realmConnectionState({
    RealmConnectionState initialOption = RealmConnectionState.online,
  }) => object.dropdown(
    label: "Realm connection",
    options: RealmConnectionState.values,
    labelBuilder: (value) => value.name.formatted,
    initialOption: initialOption,
  );

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
