import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

final _modes = <String, InteractionMode Function()>{
  "Normal": () => const NormalMode(),
  "Insert": () => const InsertMode(),
  "Graph move": () => const GraphMoveMode(),
  "Graph resize": GraphResizeMode.new,
};

/// The [ModeDisplayWidget] of the app bar following the current mode: pick
/// another Mode to watch its chip change; a mode with no look shows nothing.
@widgetbook.UseCase(name: "Following the mode", type: ModeDisplayWidget)
Widget modeDisplayWidgetUseCase(BuildContext context) {
  final mode = context.knobs.object.segmented(
    label: "Mode",
    options: _modes.keys.toList(),
    initialOption: "Insert",
  );
  return Story(
    const [],
    at: PanelLocation.component(_ModeSetter(mode: _modes[mode]!)),
  );
}

class _ModeSetter extends HookConsumerWidget {
  const _ModeSetter({required this.mode});

  final InteractionMode Function() mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Future.microtask(
        () => ref.read(currentInteractionModeProvider.notifier).setMode(mode()),
      );
      return null;
    }, [mode]);
    return const ModeDisplayWidget();
  }
}
