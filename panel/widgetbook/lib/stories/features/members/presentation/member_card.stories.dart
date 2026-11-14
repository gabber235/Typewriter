import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/membership.dart";
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/support/story.dart";

/// One member card of a smaller window. Pressing it grows the card to show
/// the member's role chips and Remove; the avatar selects. Roles show once
/// they load, and stay hidden when they fail.
@widgetbook.UseCase(name: "Default", type: MemberTabletCard)
Widget memberTabletCardUseCase(BuildContext context) {
  final longName = context.knobs.boolean(label: "Long name");
  final selected = context.knobs.boolean(label: "Selected");
  final roles = context.knobs.object.segmented(
    label: "Roles",
    options: const ["Ready", "Loading", "Failing"],
    initialOption: "Ready",
  );
  final width = context.knobs.double.slider(
    label: "Width",
    initialValue: 480,
    min: 280,
    max: 760,
  );
  final member = storyMembers(Generator(1), 2)[longName ? 1 : 0];
  return Story(
    [
      membership(
        roles: roles == "Ready" ? storyRoles : null,
        members: [member],
        failure: roles == "Failing"
            ? StateError("The membership service is unreachable")
            : null,
      ),
      ...context.knobs.motion(),
    ],
    at: PanelLocation.component(
      StoryBox(
        width: width,
        child: StoryRows(
          items: [member],
          identity: (member) => member.userId,
          selected: selected ? {member.userId} : const {},
          builder: (context, selection) {
            final isSelected = selection.selectedIds.value.contains(
              member.userId,
            );
            return MemberTabletCard(
              member: member,
              isSelected: isSelected,
              onSelectionChanged: (picked) => selection.selectedIds.value =
                  picked ? {member.userId} : const {},
              onSelectAll: () => selection.selectedIds.value = {member.userId},
              onClearSelection: () => selection.selectedIds.value = const {},
              hasSelection: isSelected,
              rows: selection.rows,
              selectedIds: selection.selectedIds.value,
              nameOf: (_) => member.name,
            );
          },
        ),
      ),
    ),
  );
}
