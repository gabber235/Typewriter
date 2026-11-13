import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/membership.dart";
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The role chips a member card edits roles with. The Founder role cannot be
/// assigned, so its chip stays disabled; the others toggle.
@widgetbook.UseCase(name: "Default", type: RoleMultiselectChips)
Widget roleMultiselectChipsUseCase(BuildContext context) {
  final catalog = context.knobs.object.segmented(
    label: "Roles",
    options: const ["None", "Few", "Many"],
    initialOption: "Few",
  );
  final picked = context.knobs.object.segmented(
    label: "Picked",
    options: const ["None", "Some", "All"],
    initialOption: "Some",
  );
  final width = context.knobs.double.slider(
    label: "Width",
    initialValue: 420,
    min: 160,
    max: 720,
  );
  final roles = switch (catalog) {
    "None" => const <skir.OrganizationRole>[],
    "Many" => [
      ...storyRoles,
      for (final (index, role) in storyRoles.skip(1).indexed)
        skir.OrganizationRole(
          roleId: skir.recordId("organization_role:${index}_copy"),
          name: "${role.name} of the realm archives",
          color: role.color,
          defaultRole: false,
          assignable: true,
          deletable: true,
        ),
    ],
    _ => storyRoles,
  };
  return Story(
    const [],
    at: PanelLocation.component(
      StoryBox(
        width: width,
        child: _Chips(
          roles: roles,
          picked: switch (picked) {
            "Some" => roles.take(3).toList(),
            "All" => roles,
            _ => const [],
          },
        ),
      ),
    ),
  );
}

/// Keeps the picked roles, as a member card does for one member.
class _Chips extends HookWidget {
  const _Chips({required this.roles, required this.picked});

  final List<skir.OrganizationRole> roles;
  final List<skir.OrganizationRole> picked;

  @override
  Widget build(BuildContext context) {
    final selected = useState(picked);
    return RoleMultiselectChips(
      availableRoles: roles,
      selectedRoles: selected.value,
      onRolesChanged: (roles) => selected.value = roles,
    );
  }
}
