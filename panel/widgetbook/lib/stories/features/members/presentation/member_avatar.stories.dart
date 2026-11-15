import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A member's avatar at the sizes the table, cards and requests use. It
/// stays the same while the member is selected.
@widgetbook.UseCase(name: "Default", type: MemberAvatar)
Widget memberAvatarUseCase(BuildContext context) {
  final radius = context.knobs.double.slider(
    label: "Radius",
    initialValue: 24,
    min: 12,
    max: 48,
  );
  return Story(
    const [],
    at: PanelLocation.component(
      Center(
        child: MemberAvatar(
          avatarUrl: "$userIconUrl&seed=grace",
          radius: radius,
        ),
      ),
    ),
  );
}
