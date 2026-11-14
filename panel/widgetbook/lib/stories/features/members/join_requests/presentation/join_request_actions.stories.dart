import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/membership.dart";
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The actions beside Select all while requests are selected: roles to
/// accept with, Accept All (or A) once a role is picked, and Decline all,
/// which holds. With nothing selected the bar is empty.
@widgetbook.UseCase(name: "Default", type: BulkJoinRequestActions)
Widget bulkJoinRequestActionsUseCase(BuildContext context) {
  final count = context.knobs.object.segmented(
    label: "Selected",
    options: const ["None", "One", "Many"],
    initialOption: "One",
  );
  final roles = context.knobs.object.segmented(
    label: "Roles",
    options: const ["Ready", "Loading"],
    initialOption: "Ready",
  );
  final requests = storyJoinRequests(Generator(1), 60);
  return Story(
    [
      membership(
        roles: roles == "Ready" ? storyRoles : null,
        joinRequests: requests,
      ),
      ...context.knobs.windows(),
      ...context.knobs.motion(),
    ],
    at: PanelLocation.component(
      Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.all(context.spacing.space6),
          child: _Bar(
            requests: requests,
            selected: switch (count) {
              "None" => 0,
              "Many" => requests.length,
              _ => 1,
            },
          ),
        ),
      ),
    ),
  );
}

/// Selects the first [selected] requests and builds the decline hold over
/// them, as the join request list does.
class _Bar extends HookWidget {
  const _Bar({required this.requests, required this.selected});

  final List<skir.OrganizationJoinRequest> requests;
  final int selected;

  @override
  Widget build(BuildContext context) {
    final rows = useAnimatedRows(
      items: requests,
      identity: (request) => request.requestId,
    );
    final ids = useState({
      for (final request in requests.take(selected)) request.requestId,
    });
    return BulkJoinRequestActions(
      selectedCount: ids.value.length,
      selectedIds: ids.value,
      onClearSelection: () => ids.value = const {},
      decline: joinRequestDecline(
        id: "story_decline_join_requests",
        label: "Decline requests",
        priority: 2,
        targets: () => ids.value,
        nameOf: (id) => rows[id]?.item.userName,
        rows: rows,
      ),
    );
  }
}
