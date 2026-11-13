import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/support/story.dart";

/// How a join code may be used: once or many times, and whether it accepts
/// whoever joins straight into its roles.
@widgetbook.UseCase(name: "Default", type: JoinCodeTypeBadges)
Widget joinCodeTypeBadgesUseCase(BuildContext context) {
  final singleUse = context.knobs.boolean(label: "Single use");
  final autoAccept = context.knobs.boolean(label: "Auto accept");
  return Story(
    const [],
    at: PanelLocation.component(
      Center(
        child: JoinCodeTypeBadges(
          code: joinCode(
            "story",
            singleUse: singleUse,
            roles: autoAccept ? [storyRoles[2].roleId] : const [],
          ),
        ),
      ),
    ),
  );
}
