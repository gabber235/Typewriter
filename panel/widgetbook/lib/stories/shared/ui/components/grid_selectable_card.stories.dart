import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// Two [GridSelectableCard]s in their identity colours. The card draws only
/// what its owner tells it: Selected fills it, Hovered raises it, Badge adds
/// the corner label. The second card has a title too long for one line.
@widgetbook.UseCase(name: "Default", type: GridSelectableCard)
Widget gridSelectableCardUseCase(BuildContext context) {
  final selected = context.knobs.boolean(label: "Selected");
  final hovered = context.knobs.boolean(label: "Hovered");
  final badge = context.knobs.boolean(label: "Badge", initialValue: true);
  return Story(
    context.knobs.motion(),
    at: PanelLocation.component(
      Builder(
        builder: (context) => Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            GridSelectableCard(
              title: "Quest",
              baseColor: context.colors.brand,
              isSelected: selected,
              isHovered: hovered,
              badgeLabel: badge ? "Entry" : null,
              badgeColor: context.colors.brand,
              badgeOnColor: context.colors.onBrand,
            ),
            GridSelectableCard(
              title: "Cinematic with a camera path through the whole harbour",
              baseColor: context.colors.accent,
              isSelected: selected,
              isHovered: hovered,
              badgeLabel: badge ? "Manifest" : null,
              badgeColor: context.colors.accent,
              badgeOnColor: context.colors.onAccent,
            ),
          ],
        ),
      ),
    ),
  );
}
