import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/authoring/presentation/retained_rename.dart";
import "package:widgetbook_workspace/support/story.dart";

@widgetbook.UseCase(name: "Retained conflict", type: AuthoringConflictNotice)
Widget authoringConflictNoticeUseCase(BuildContext context) {
  return Story(
    [
      ...retainedRenameWorld(_savedKnob(context)),
      ...context.knobs.traits("Saved values", {
        "Readable": const [],
        "Unreadable": const [savedDocumentUnreadable],
      }),
    ],
    at: PanelLocation.component(
      SizedBox(
        width: _width(context, 420),
        child: RetainedRename(
          builder: (context, workspace, group) =>
              AuthoringConflictNotice(workspace: workspace, group: group),
        ),
      ),
    ),
  );
}

@widgetbook.UseCase(
  name: "Complete group comparison",
  type: AuthoringConflictComparison,
)
Widget authoringConflictComparisonUseCase(BuildContext context) {
  return Story(
    retainedRenameWorld(_savedKnob(context)),
    at: PanelLocation.component(
      SizedBox(
        width: _width(context, 700),
        child: RetainedRename(
          builder: (context, workspace, group) =>
              _Comparison(workspace: workspace, group: group),
        ),
      ),
    ),
  );
}

List<void Function(AuthoringEdit edit)> _savedKnob(BuildContext context) {
  final saved = context.knobs.object.dropdown(
    label: "Saved Realm",
    options: savedChanges.keys.skip(1).toList(),
  );
  return savedChanges[saved]!;
}

double _width(BuildContext context, double initial) => context.knobs.double
    .slider(label: "Width", initialValue: initial, min: 320, max: 900);

/// The comparison of the retained rename against the saved Realm, reviewed
/// once when the conflict arrives; later saves elsewhere leave that review
/// behind, as they do for a user still reading it.
class _Comparison extends HookWidget {
  const _Comparison({required this.workspace, required this.group});

  final RealmEditing workspace;
  final EditGroupId group;

  @override
  Widget build(BuildContext context) {
    final phase = workspace.state.groups[group]?.phase;
    final review = useRef<AuthoringConflictReview?>(null);
    if (phase == null || !phase.blocked) review.value = null;
    if (review.value == null && phase != null && phase.blocked) {
      review.value = const RealmEditModel().review(
        group,
        workspace.workspace.inspectUnsubmitted(group),
      );
    }
    final current = review.value;
    if (current == null) return const SizedBox.shrink();
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.space3),
        child: AuthoringConflictComparison(
          review: current,
          onKeepMine: current.canKeepMine
              ? () => workspace.resolveConflict(
                  current,
                  AuthoringConflictChoice.keepMine,
                )
              : null,
          onUseSaved: () => workspace.resolveConflict(
            current,
            AuthoringConflictChoice.useSaved,
          ),
        ),
      ),
    );
  }
}
