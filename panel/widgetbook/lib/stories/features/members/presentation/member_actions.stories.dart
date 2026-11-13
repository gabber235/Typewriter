import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/membership.dart";
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The bar above the member list while members are selected: the count,
/// roles to assign with Apply (or A), and Remove, which holds. Clearing the
/// selection here sets the count to zero.
@widgetbook.UseCase(name: "Default", type: BulkMemberActions)
Widget bulkMemberActionsUseCase(BuildContext context) {
  final count = context.knobs.object.segmented(
    label: "Selected",
    options: const ["One", "Few", "Many"],
    initialOption: "Few",
  );
  final roles = context.knobs.object.segmented(
    label: "Roles",
    options: const ["Ready", "Loading"],
    initialOption: "Ready",
  );
  final members = storyMembers(Generator(1), switch (count) {
    "One" => 1,
    "Many" => 60,
    _ => 3,
  });
  return Story(
    [
      membership(roles: roles == "Ready" ? storyRoles : null, members: members),
      ...context.knobs.windows(),
      ...context.knobs.motion(),
    ],
    at: PanelLocation.component(
      Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.all(context.spacing.space6),
          child: _Bar(members: members),
        ),
      ),
    ),
  );
}

/// Selects every member and builds the remove hold over them, as the
/// members tab does.
class _Bar extends HookWidget {
  const _Bar({required this.members});

  final List<skir.OrganizationMember> members;

  @override
  Widget build(BuildContext context) {
    final rows = useAnimatedRows(
      items: members,
      identity: (member) => member.userId,
    );
    final selected = useState({for (final member in members) member.userId});
    return BulkMemberActions(
      selectedCount: selected.value.length,
      selectedIds: selected.value,
      removal: memberRemoval(
        id: "story_remove_members",
        label: "Remove members",
        priority: 2,
        targets: () => selected.value,
        nameOf: (id) => rows[id]?.item.name,
        rows: rows,
      ),
      onUnselect: (ids) => selected.value = selected.value.difference(ids),
    );
  }
}
