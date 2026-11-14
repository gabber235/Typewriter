import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The [MixedValueMessage] the inspector shows when the selected resources
/// hold different values for one field.
@widgetbook.UseCase(name: "Default", type: MixedValueMessage)
Widget mixedValueMessageUseCase(BuildContext context) {
  return const Story(
    [],
    at: PanelLocation.component(
      SizedBox(width: 320, child: MixedValueMessage()),
    ),
  );
}

/// The [MixedSwitchTile] a switch becomes when the selected items hold the
/// setting differently: a striped track with the thumb in the middle. A
/// press turns it on for every item.
@widgetbook.UseCase(name: "Default", type: MixedSwitchTile)
Widget mixedSwitchTileUseCase(BuildContext context) {
  final enabled = context.knobs.boolean(label: "Enabled", initialValue: true);
  final leading = context.knobs.boolean(label: "Switch first");
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: 320,
        child: MixedSwitchTile(
          title: const Text(mixedValueLabel),
          leading: leading,
          onPressed: enabled ? () {} : null,
        ),
      ),
    ),
  );
}

/// The [MixedSlider] a slider becomes when the selected items hold different
/// numbers: a striped track without a thumb. A click or a drag sets the
/// value under the pointer for every item; an arrow key steps from the first
/// item's value.
@widgetbook.UseCase(name: "Default", type: MixedSlider)
Widget mixedSliderUseCase(BuildContext context) {
  final enabled = context.knobs.boolean(label: "Enabled", initialValue: true);
  final divisions = context.knobs.boolean(label: "Steps of ten");
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: 320,
        child: MixedSlider(
          min: 0,
          max: 100,
          start: 30,
          divisions: divisions ? 10 : null,
          onChanged: enabled ? (_) {} : null,
        ),
      ),
    ),
  );
}
