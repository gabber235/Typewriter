import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/support/story.dart";

@widgetbook.UseCase(name: "Default", type: JoinCodeSettings)
Widget joinCodeSettingsUseCase(BuildContext context) {
  final roles = context.knobs.object.segmented(
    label: "Roles",
    options: const ["None", "All"],
    initialOption: "All",
  );
  final initial = context.knobs.object.dropdown(
    label: "Options",
    options: const ["Default", "Never expires", "Auto accept"],
    initialOption: "Default",
  );
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: 420,
        child: JoinCodeSettings(
          availableRoles: roles == "None" ? const [] : storyRoles,
          initialOptions: switch (initial) {
            "Never expires" => const JoinCodeOptions(
              expiration: JoinCodeExpiration.never(),
              singleUse: false,
            ),
            "Auto accept" => JoinCodeOptions(
              autoAcceptRoleIds: [storyRoles[2].roleId],
            ),
            _ => const JoinCodeOptions(),
          },
          onOptionsChanged: (_) {},
        ),
      ),
    ),
  );
}
