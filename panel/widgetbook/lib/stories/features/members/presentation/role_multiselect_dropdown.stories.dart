import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/support/story.dart";

@widgetbook.UseCase(name: "Default", type: RoleMultiselectDropdown)
Widget roleMultiselectDropdownUseCase(BuildContext context) {
  final many = [
    ...storyRoles,
    for (final (index, name) in const [
      "Quest designer",
      "Dialogue writer",
      "Cinematics",
      "Level builder",
      "Translator",
      "Play tester",
      "Community manager",
      "Release manager",
      "Sound designer",
      "Lore keeper",
    ].indexed)
      skir.OrganizationRole(
        roleId: skir.recordId("organization_role:${name.snakeCase()}"),
        name: name,
        color: Colors.primaries[index].toSkirColor(),
        defaultRole: false,
        assignable: true,
        deletable: true,
      ),
  ];
  return Story(
    context.knobs.traits("Roles", initial: "Few", {
      "None": [membership(roles: const [])],
      "Few": [membership(roles: storyRoles)],
      "Many": [membership(roles: many)],
      "Loading": [membership(roles: null)],
      "Failing": [
        membership(
          roles: null,
          failure: StateError("The membership service is unreachable"),
        ),
      ],
    }),
    at: PanelLocation.component(
      SizedBox(
        width: context.knobs.double.slider(
          label: "Width",
          initialValue: 360,
          min: 200,
          max: 640,
        ),
        child: const _Roles(),
      ),
    ),
  );
}

/// Keeps the picked roles, as the member table does for one member.
class _Roles extends HookWidget {
  const _Roles();

  @override
  Widget build(BuildContext context) {
    final roles = useState<List<skir.OrganizationRole>>([storyRoles.first]);
    return RoleMultiselectDropdown(
      selectedRoles: roles.value,
      onRolesChanged: (picked) => roles.value = picked,
      placeholder: "Pick roles",
    );
  }
}
