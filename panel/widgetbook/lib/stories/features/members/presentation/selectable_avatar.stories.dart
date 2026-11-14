import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A member's avatar, which turns into a check while the member is
/// selected, at the sizes the table, cards and requests use.
@widgetbook.UseCase(name: "Default", type: SelectableAvatar)
Widget selectableAvatarUseCase(BuildContext context) {
  final selected = context.knobs.boolean(label: "Selected");
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
        child: SelectableAvatar(
          avatarUrl: "$userIconUrl&seed=grace",
          isSelected: selected,
          radius: radius,
        ),
      ),
    ),
  );
}
