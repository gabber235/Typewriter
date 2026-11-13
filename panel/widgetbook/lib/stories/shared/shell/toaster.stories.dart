import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// Toasts from actions that fail, next to the Activity they land in. Publish
/// keeps failing, Save works on its retry, Three fails three times at once,
/// and Join shows a success. T moves to the newest toast, R retries, and
/// Escape dismisses.
@widgetbook.UseCase(name: "Failures and Activity", type: Toaster)
Widget toasterUseCase(BuildContext context) {
  return const Story([], at: PanelLocation.component(_FailingActions()));
}

class _FailingActions extends HookWidget {
  const _FailingActions();

  @override
  Widget build(BuildContext context) {
    final work = useMemoized(ScopedWorkSession.new);
    useEffect(() => work.dispose, [work]);
    final saves = useRef(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ScopedWorkSessionActivityView(controller: work),
        Expanded(
          child: Center(
            child: Wrap(
              spacing: 8,
              children: [
                Button(
                  label: "Publish",
                  autofocus: true,
                  onPressed: () async =>
                      throw ApiException.badRequest("No engine target"),
                ),
                Button(
                  label: "Save",
                  onPressed: () async {
                    if ((saves.value++).isEven) {
                      throw ApiException.badRequest("The realm is offline");
                    }
                  },
                ),
                Button(
                  label: "Three",
                  onPressed: () {
                    for (final page in ["Intro", "Quest", "Ending"]) {
                      context.reportFailure(
                        "Publish $page failed",
                        detail: "No engine target",
                      );
                    }
                  },
                ),
                Button(
                  label: "Join",
                  onPressed: () => context.reportSuccess("Join request sent"),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
