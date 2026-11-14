import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

final _modes = <String, ModeDisplay>{
  "Normal": const NormalMode(),
  "Insert": const InsertMode(),
  "Graph move": GraphMoveMode(),
  "Graph resize": GraphResizeMode(),
};

/// The chips of the real interaction modes, as the app bar shows them.
@widgetbook.UseCase(name: "Every mode", type: ModeChip)
Widget modeChipUseCase(BuildContext context) {
  return Story(
    const [],
    at: PanelLocation.component(
      Builder(
        builder: (context) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              for (final mode in _modes.values)
                ModeChip(look: mode.look(context)),
            ],
          );
        },
      ),
    ),
  );
}

/// One chip moving between modes: pick another mode to watch the label type
/// and the fill follow it.
@widgetbook.UseCase(name: "Switching", type: ModeChip)
Widget modeChipSwitchingUseCase(BuildContext context) {
  final mode = context.knobs.object.dropdown(
    label: "Mode",
    options: _modes.keys.toList(),
  );
  return Story(
    const [],
    at: PanelLocation.component(
      Builder(
        builder: (context) => ModeChip(look: _modes[mode]!.look(context)),
      ),
    ),
  );
}
