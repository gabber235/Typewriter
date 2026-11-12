import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The chips of the real interaction modes, as the app bar shows them.
@widgetbook.UseCase(name: "Default", type: ModeDisplayChip)
Widget modeDisplayChipUseCase(BuildContext context) {
  return Story(
    const [],
    at: PanelLocation.component(
      Builder(
        builder: (context) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              for (final mode in <ModeDisplay>[
                const NormalMode(),
                const InsertMode(),
                GraphMoveMode(),
                GraphResizeMode(),
              ])
                mode.buildDisplay(context),
            ],
          );
        },
      ),
    ),
  );
}
