import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/membership.dart";
import "package:widgetbook_workspace/data/features/organization.dart";

/// The selectable table the member and join code tables share, with plain
/// rows: the header checkbox selects all, some or none, and each row's
/// checkbox toggles it.
@widgetbook.UseCase(name: "Default", type: SelectionTable)
Widget selectionTableUseCase(BuildContext context) {
  return selectableRowsStory(
    context,
    label: "Rows",
    make: storyMembers,
    identity: (member) => member.userId,
    traits: (_) => const [],
    builder: (selection) => SelectionTable<skir.OrganizationMember>(
      selection: selection,
      idOf: (member) => member.userId,
      noun: "members",
      labels: const ["Name", "Email"],
      columnWidths: const {
        0: FixedColumnWidth(48),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FixedColumnWidth(48),
      },
      emptyBuilder: (context) => const EmptyState(
        icon: MaterialSymbols.groups_2_rounded,
        title: "Nothing to select",
        description: "Rows appear here once there are some.",
      ),
      rowBuilder: (context, entry) {
        final id = entry.item.userId;
        final isSelected = selection.selectedIds.value.contains(id);
        void toggle() => selection.selectedIds.value = isSelected
            ? selection.selectedIds.value.difference({id})
            : {...selection.selectedIds.value, id};
        final padding = EdgeInsets.all(context.spacing.space3);
        return TableRow(
          key: ValueKey(id),
          children: [
            Padding(
              padding: padding,
              child: SelectionCheck(value: isSelected, onChanged: toggle),
            ),
            for (final text in [entry.item.name, entry.item.email])
              Padding(
                padding: padding,
                child: Text(text ?? "", overflow: TextOverflow.ellipsis),
              ),
            const SizedBox.shrink(),
          ],
        );
      },
    ),
  );
}
