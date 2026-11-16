import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The work a story puts into a work session before its activity shows it.
enum _Work {
  /// Nothing to save: the activity hides itself.
  none,

  /// An unsaved edit, so leaving asks first.
  draft,

  /// A save whose answer never arrives.
  saving,

  /// A save the server refused.
  refused,
}

/// Puts [work] into [session], the way an editor or a page action would.
void _seed(LocalWorkCommands session, _Work work) {
  switch (work) {
    case _Work.none:
      break;
    case _Work.draft:
      session.register(UnsavedWork());
    case _Work.saving:
      final submission = MutationSubmission<void>(
        id: "rename",
        label: "Rename book",
        send: () => Completer<SubmissionResult<void>>().future,
      );
      session.track(submission);
      unawaited(submission.run());
    case _Work.refused:
      final submission = MutationSubmission<void>(
        id: "rename",
        label: "Rename book",
        send: () async => const SubmissionResult.rejected(
          message: "Another book already has this name",
        ),
      );
      session.track(submission);
      unawaited(submission.run());
  }
}

_Work _workKnob(BuildContext context) => context.knobs.object.dropdown(
  label: "Work",
  options: _Work.values,
  initialOption: _Work.draft,
  labelBuilder: (work) => work.name,
);

List<Trait> _windowKnob(BuildContext context) =>
    context.knobs.traits("Window", {
      "Desktop": const [],
      "Compact": const [compact],
    });

/// The [MutationActivityButton] of the app bar over the panel's own work
/// session: hidden with nothing to save, otherwise the state of the work.
/// It opens its details as a popup on desktop and as a sheet in a compact
/// window.
@widgetbook.UseCase(name: "Default", type: MutationActivityButton)
Widget mutationActivityButtonUseCase(BuildContext context) {
  final work = _workKnob(context);
  return Story(
    [signedIn(ada, organization: acme), ..._windowKnob(context)],
    at: PanelLocation.component(
      HookConsumer(
        builder: (context, ref, _) {
          useEffect(() {
            // The work session publishes to providers, which must not change
            // while the story builds.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                _seed(ref.read(localWorkControllerProvider), work);
              }
            });
            return null;
          }, const []);
          return const MutationActivityButton();
        },
      ),
    ),
  );
}

/// The [ScopedWorkSessionActivityView] of a short lived work session, such
/// as one a dialog owns: it shows the session's current state at once and
/// follows its changes.
@widgetbook.UseCase(name: "Default", type: ScopedWorkSessionActivityView)
Widget scopedWorkSessionActivityViewUseCase(BuildContext context) {
  final work = _workKnob(context);
  return Story(
    [signedIn(ada, organization: acme), ..._windowKnob(context)],
    at: PanelLocation.component(
      HookBuilder(
        builder: (context) {
          final session = useMemoized(() {
            final session = ScopedWorkSession();
            _seed(session, work);
            return session;
          });
          useEffect(() => session.dispose, [session]);
          return ScopedWorkSessionActivityView(controller: session);
        },
      ),
    ),
  );
}
