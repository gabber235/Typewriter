import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Desktop row control that removes one member with a hold.
///
/// While the remove sends the row stays in place, struck through; a refusal
/// leaves it in place with its message, and success lets the removal event
/// take it out.
class MemberRowActions extends StatelessWidget {
  const MemberRowActions({required this.member, required this.rows, super.key});

  final skir.OrganizationMember member;

  /// The members rows the tab owns.
  final AnimatedRows<Object?> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.spacing.space2),
      child: CommandButton(
        face: ButtonFace.icon,
        color: context.colors.danger,
        icon: const Icon(Icons.person_remove_outlined, size: 20),
        label: "Remove member",
        command: memberRemoval(
          id: "remove_table_member_${member.userId}",
          label: "Remove member",
          targets: () => {member.userId},
          nameOf: (_) => member.name,
          rows: rows,
        ),
      ),
    );
  }
}
