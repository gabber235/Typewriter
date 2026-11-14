import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// One card that comes in with [Enter]; Replay mounts it again. `rowIn`
/// slides a row in that was added later; `loadIn` outside a run shows at
/// once, as content that loaded before the page drew.
@widgetbook.UseCase(name: "Default", type: Enter)
Widget enterUseCase(BuildContext context) {
  final token = context.knobs.object.segmented(
    label: "Token",
    options: const [MotionToken.rowIn, MotionToken.loadIn],
    initialOption: MotionToken.rowIn,
    labelBuilder: (token) => token == MotionToken.rowIn ? "rowIn" : "loadIn",
  );
  return Story(
    context.knobs.motion(),
    at: PanelLocation.component(
      _Replay(
        builder: (context) => Enter(token: token, child: const _Card("Ada")),
      ),
    ),
  );
}

/// Five cards that join one [EnterRun] with `loadIn`: they start top to
/// bottom, spread by the load stagger. Replay starts a new run.
@widgetbook.UseCase(name: "Load run", type: EnterRun)
Widget enterRunUseCase(BuildContext context) {
  return Story(
    context.knobs.motion(),
    at: PanelLocation.component(
      _Replay(
        builder: (context) => EnterRun(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              for (final name in const [
                "Ada",
                "Grace",
                "Linus",
                "Ken",
                "Bjarne",
              ])
                Enter(token: MotionToken.loadIn, child: _Card(name)),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Replay extends HookWidget {
  const _Replay({required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final run = useState(0);
    return SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Button(label: "Replay", onPressed: () => run.value++),
          KeyedSubtree(
            key: ValueKey(run.value),
            child: Builder(builder: builder),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: context.shapes.mediumBorderRadius,
      ),
      child: PanelRow(dense: true, title: Text(name)),
    );
  }
}
