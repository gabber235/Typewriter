import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// What the inspector shows for one join code: its link, the roles it
/// grants straight away, how often it works and when it expires. Copy is
/// one of its operations.
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
