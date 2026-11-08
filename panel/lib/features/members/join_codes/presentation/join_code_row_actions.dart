import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Desktop row control for revoking one join code with a hold. While the
/// revoke sends the row stays struck through; a refusal leaves it in place
/// with its message.
class JoinCodeRowActions extends StatelessWidget {
  const JoinCodeRowActions({required this.code, required this.rows, super.key});

  final skir.JoinCode code;

  /// The join code rows the tab owns.
  final AnimatedRows<Object?> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.spacing.space2),
      child: CommandButton(
        face: ButtonFace.icon,
        color: context.colors.danger,
        icon: const Icon(Icons.link_off, size: 20),
        label: "Revoke join code",
        command: joinCodeRevocation(
          id: "revoke_table_join_code_${code.code}",
          label: "Revoke join code",
          targets: () => {code.code},
          rows: rows,
        ),
      ),
    );
  }
}
