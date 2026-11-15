import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The organization's roles as checks over the roles each of several items
/// holds, as the inspector shows them for members and join requests.
///
/// [held] gives each item's role ids; a press hands [onChanged] every
/// item's next role ids, in the same order, with the roles they name.
/// Protected roles show disabled, or not at all with [assignableOnly].
/// Moving into the inspector lands on the first role.
class RoleChecks extends ConsumerWidget {
  const RoleChecks({
    required this.held,
    required this.onChanged,
    this.assignableOnly = false,
    super.key,
  });

  final List<Set<skir.RecordId>> held;
  final void Function(
    List<Set<skir.RecordId>> next,
    List<skir.OrganizationRole> roles,
  )
  onChanged;
  final bool assignableOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(organizationRolesProvider)
        .call(
          name: "Roles",
          shrink: true,
          builder: (roles) => FieldLanding(
            child: CheckOptionSet<skir.RecordId>(
              choices: [
                for (final role in roles)
                  if (!assignableOnly || role.assignable)
                    CheckChoice(
                      key: role.roleId,
                      label: role.name,
                      enabled: role.assignable,
                    ),
              ],
              held: held,
              onChanged: (next) => onChanged(next, roles),
            ),
          ),
        );
  }
}
