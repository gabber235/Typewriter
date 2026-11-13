import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/membership.dart";
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/support/story.dart";

/// One join request: pressing it selects it, Decline holds, and Accept grows
/// the card to pick roles before approving. On desktop it is one row; on
/// smaller windows its controls stack.
@widgetbook.UseCase(name: "Default", type: JoinRequestCard)
Widget joinRequestCardUseCase(BuildContext context) {
  final longName = context.knobs.boolean(label: "Long name, expiring");
  final selected = context.knobs.boolean(label: "Selected");
  final roles = context.knobs.object.segmented(
    label: "Roles",
    options: const ["Ready", "Loading", "Failing"],
    initialOption: "Ready",
  );
  final request = storyJoinRequests(Generator(1), 2)[longName ? 1 : 0];
  return Story(
    [
      membership(
        roles: roles == "Ready" ? storyRoles : null,
        joinRequests: [request],
        failure: roles == "Failing"
            ? StateError("The membership service is unreachable")
            : null,
      ),
      ...context.knobs.windows(),
      ...context.knobs.motion(),
    ],
    at: PanelLocation.component(
      Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.all(context.spacing.space6),
          child: StoryRows(
            items: [request],
            identity: (request) => request.requestId,
            selected: selected ? {request.requestId} : const {},
            builder: (context, selection) {
              final isSelected = selection.selectedIds.value.contains(
                request.requestId,
              );
              return JoinRequestCard(
                request: request,
                isSelected: isSelected,
                onSelectionChanged: (picked) => selection.selectedIds.value =
                    picked ? {request.requestId} : const {},
                onSelectAll: () =>
                    selection.selectedIds.value = {request.requestId},
                onClearSelection: () => selection.selectedIds.value = const {},
                hasSelection: isSelected,
                rows: selection.rows,
                selectedIds: selection.selectedIds.value,
                nameOf: (_) => request.userName,
              );
            },
          ),
        ),
      ),
    ),
  );
}
