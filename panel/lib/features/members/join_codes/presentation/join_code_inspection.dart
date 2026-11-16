import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// What the inspector shows for one join code: its link with a Copy
/// button, the roles it grants straight away, how often it works and when
/// it expires.
class JoinCodeInspection extends StatelessWidget {
  const JoinCodeInspection({
    required this.code,
    required this.roles,
    super.key,
  });

  final skir.JoinCode code;

  /// The roles a newcomer is granted without approval.
  final List<skir.OrganizationRole> roles;

  @override
  Widget build(BuildContext context) {
    final url = joinCodeUrl(code.code);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: context.spacing.space3,
      children: [
        BlurReveal(blurSigma: 3, child: Text(url, style: text.bodyMedium)),
        CommandButton(
          command: joinCodeCopy(code),
          face: ButtonFace.outlined,
          icon: const Icon(Icons.copy, size: 16),
          label: "Copy Join Code",
          doneLabel: "Copied",
        ),
        InspectionDetail(
          label: "Roles",
          child: Text(
            roles.isEmpty
                ? "None. Requests wait for approval."
                : roles.map((role) => role.name).join(", "),
            style: text.bodyMedium,
          ),
        ),
        InspectionDetail(
          label: "Uses",
          child: Text(
            code.singleUse ? "Works once" : "Works until revoked",
            style: text.bodyMedium,
          ),
        ),
        InspectionDetail(
          label: "Expires",
          child: CountdownBadge(endDate: code.expiresAt),
        ),
      ],
    );
  }
}

/// The one Copy join code command for [code]: its row button and the
/// inspector button both build it, so each says Copied. It has no key, as
/// rows bind none of their own.
ActionShortcut joinCodeCopy(skir.JoinCode code) {
  final url = joinCodeUrl(code.code);
  return ActionShortcut(
    id: "copy_join_code_${code.code}",
    label: "Copy join code",
    description: "Copy this join code",
    activators: const [],
    priority: 1,
    run: ActionRun.press((_) => Clipboard.setData(ClipboardData(text: url))),
  );
}
