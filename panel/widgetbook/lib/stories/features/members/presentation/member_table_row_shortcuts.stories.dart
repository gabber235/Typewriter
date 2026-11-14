import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/membership.dart";
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The keys of one focused member row: Space toggles the selection,
/// Shift+Space selects all, Escape clears it, and holding Delete removes the
/// member, or the whole selection when the row is in it. The line under the
/// row names the last key's action.
@widgetbook.UseCase(name: "Default", type: MemberTableRowShortcuts)
Widget memberTableRowShortcutsUseCase(BuildContext context) {
  final selected = context.knobs.boolean(label: "Selected with another");
  final members = storyMembers(Generator(1), 3).skip(1).toList();
  return Story(
    [
      membership(roles: storyRoles, members: members),
      ...context.knobs.motion(),
    ],
    at: PanelLocation.component(
      StoryBox(
        width: 480,
        child: _Row(members: members, selected: selected),
      ),
    ),
  );
}

/// One member row whose shortcuts write what they did under it.
class _Row extends HookWidget {
  const _Row({required this.members, required this.selected});

  final List<skir.OrganizationMember> members;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final member = members.first;
    final last = useState("Nothing pressed yet");
    final rows = useAnimatedRows(
      items: members,
      identity: (member) => member.userId,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: context.spacing.space3,
      children: [
        MemberTableRowShortcuts(
          member: member,
          onToggleSelection: () => last.value = "Toggled the selection",
          onSelectAll: () => last.value = "Selected all members",
          onClearSelection: () => last.value = "Cleared the selection",
          isSelected: selected,
          hasSelection: selected,
          rows: rows,
          selectedIds: selected
              ? {for (final member in members) member.userId}
              : const {},
          nameOf: (id) => rows[id]?.item.name,
          child: Button(
            face: ButtonFace.bare,
            label: member.name ?? "Member",
            autofocus: true,
            onPressed: () => last.value = "Clicked the row",
            child: Padding(
              padding: EdgeInsets.all(context.spacing.space3),
              child: PersonSummary(name: member.name, email: member.email),
            ),
          ),
        ),
        Text(last.value),
      ],
    );
  }
}
