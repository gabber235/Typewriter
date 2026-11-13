import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

/// A page whose "Publish" always fails with [publishFailure] and whose "Save"
/// fails with [saveFailure] once and works after, next to the Activity of
/// [work]. "Publish" holds the focus at first.
final class FailingActionsPage extends HookWidget {
  const FailingActionsPage({required this.work, super.key});

  static const publishFailure = "No engine target";
  static const saveFailure = "The realm is offline";

  final ScopedWorkSession work;

  @override
  Widget build(BuildContext context) {
    final saves = useRef(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ScopedWorkSessionActivityView(controller: work),
        Expanded(
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Button(
                  label: "Publish",
                  autofocus: true,
                  onPressed: () async =>
                      throw ApiException.badRequest(publishFailure),
                ),
                Button(
                  label: "Save",
                  onPressed: () async {
                    if (saves.value++ == 0) {
                      throw ApiException.badRequest(saveFailure);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Shows [FailingActionsPage], next to the Activity of its own work session.
extension ShowFailingActions on WidgetTester {
  Future<PanelDriver> showFailingActions() =>
      pumpPanel(const [], at: PanelLocation.component(_FailingStage()));

  /// Presses [key] and draws one frame, so a toast it raises has not drained.
  Future<void> tapKey(LogicalKeyboardKey key) async {
    await sendKeyEvent(key);
    await pump();
  }

  /// Fails the focused action and moves to its toast with T.
  Future<void> failIntoToast() async {
    await tapKey(LogicalKeyboardKey.enter);
    await tapKey(LogicalKeyboardKey.keyT);
  }
}

class _FailingStage extends HookWidget {
  const _FailingStage();

  @override
  Widget build(BuildContext context) {
    final work = useMemoized(ScopedWorkSession.new);
    useEffect(() => work.dispose, [work]);
    return FailingActionsPage(work: work);
  }
}

/// A failure whose outcome is unknown, as a save that may have landed throws.
final class UnknownOutcome implements UnconfirmedFailure {
  const UnknownOutcome();
}
