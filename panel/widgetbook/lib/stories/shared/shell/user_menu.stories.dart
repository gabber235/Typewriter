import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

const _usernameOnly = PanelUser(
  id: "builder_42",
  name: "builder_42",
  claims: {"name": null},
);

const _subjectOnly = PanelUser(
  id: "7f3c2a91",
  name: "7f3c2a91",
  claims: {"name": null, "preferred_username": null},
);

/// The [UserMenu] at the foot of every sidebar, for users the identity
/// provider names fully, by username only or by subject only; it opens the
/// account and appearance menu.
@widgetbook.UseCase(name: "Default", type: UserMenu)
Widget userMenuUseCase(BuildContext context) {
  final user = context.knobs.object.segmented(
    label: "User",
    options: const [ada, _usernameOnly, _subjectOnly],
    labelBuilder: (user) => switch (user) {
      _usernameOnly => "Username only",
      _subjectOnly => "Subject only",
      _ => "Name and email",
    },
    initialOption: ada,
  );
  final compact = context.knobs.boolean(label: "Compact");
  return Story(
    [signedIn(user, organization: acme)],
    at: PanelLocation.component(
      SizedBox(
        width: compact ? 64 : 280,
        child: UserMenu(compact: compact),
      ),
    ),
  );
}
