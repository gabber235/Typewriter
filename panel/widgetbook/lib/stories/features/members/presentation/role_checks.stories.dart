import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/support/story.dart";

/// Acme's roles as checks over two members: a role both hold is checked,
/// one only one holds says "1 of 2", and protected roles show disabled or,
/// for a join request, not at all.
@widgetbook.UseCase(name: "Default", type: RoleChecks)
Widget roleChecksUseCase(BuildContext context) {
  final assignableOnly = context.knobs.boolean(
    label: "Assignable only",
    initialValue: false,
  );
  return Story(
    [membership(roles: storyRoles)],
    at: PanelLocation.component(
      SizedBox(width: 320, child: _TwoMembers(assignableOnly: assignableOnly)),
    ),
  );
}

/// Two members holding the first two and the second story role.
class _TwoMembers extends HookWidget {
  const _TwoMembers({required this.assignableOnly});

  final bool assignableOnly;

  @override
  Widget build(BuildContext context) {
    final held = useState(<Set<skir.RecordId>>[
      {for (final role in storyRoles.take(2)) role.roleId},
      {storyRoles[1].roleId},
    ]);
    return RoleChecks(
      assignableOnly: assignableOnly,
      held: held.value,
      onChanged: (next, _) => held.value = next,
    );
  }
}
