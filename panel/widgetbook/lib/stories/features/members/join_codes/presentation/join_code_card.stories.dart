import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/membership.dart";
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/support/story.dart";

/// One join code card of a smaller window. Pressing it grows the card to
/// show Copy and Revoke; the link icon selects.
@widgetbook.UseCase(name: "Default", type: JoinCodeCard)
Widget joinCodeCardUseCase(BuildContext context) {
  final kind = context.knobs.object.segmented(
    label: "Code",
    options: const ["Expiring single use", "Never expires, auto accept"],
    initialOption: "Expiring single use",
  );
  final selected = context.knobs.boolean(label: "Selected");
  final width = context.knobs.double.slider(
    label: "Width",
    initialValue: 480,
    min: 280,
    max: 760,
  );
  final code = storyJoinCodes(
    Generator(1),
    2,
  )[kind == "Expiring single use" ? 0 : 1];
  return Story(
    [
      membership(roles: storyRoles, joinCodes: [code]),
      ...context.knobs.motion(),
    ],
    at: PanelLocation.component(
      StoryBox(
        width: width,
        child: StoryRows(
          items: [code],
          identity: (code) => code.code,
          selected: selected ? {code.code} : const {},
          builder: (context, selection) {
            final isSelected = selection.selectedIds.value.contains(code.code);
            return JoinCodeCard(
              code: code,
              isSelected: isSelected,
              onSelectionChanged: (picked) =>
                  selection.selectedIds.value = picked ? {code.code} : const {},
              onSelectAll: () => selection.selectedIds.value = {code.code},
              onClearSelection: () => selection.selectedIds.value = const {},
              hasSelection: isSelected,
              rows: selection.rows,
              selectedIds: selection.selectedIds.value,
            );
          },
        ),
      ),
    ),
  );
}
