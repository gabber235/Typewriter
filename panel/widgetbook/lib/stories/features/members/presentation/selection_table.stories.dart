import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/membership.dart";
import "package:widgetbook_workspace/data/features/organization.dart";

/// The selectable table the member and join code tables share, with plain
/// rows: a click selects one row, Space or a modifier click adds rows, and
/// in select mode every row shows its check.
@widgetbook.UseCase(name: "Default", type: SelectionTable)
Widget selectionTableUseCase(BuildContext context) {
  return selectableRowsStory(
    context,
    label: "Rows",
    make: storyMembers,
    identity: (member) => member.userId,
    selectable: (member) => MemberIdentifier(member.userId),
    traits: (_) => const [],
    builder: (rows) => SelectionTable<skir.OrganizationMember>(
      rows: rows,
      selectableOf: (member) => MemberIdentifier(member.userId),
      labelOf: (member) => member.displayName,
      labels: const ["Name", "Email"],
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
      },
      emptyBuilder: (context) => const EmptyState(
        icon: MaterialSymbols.groups_2_rounded,
        title: "Nothing to select",
        description: "Rows appear here once there are some.",
      ),
      leadingBuilder: (context, member) => MemberAvatar(
        avatarUrl: "$userIconUrl&seed=${member.userId}",
        radius: 16,
      ),
      cellsBuilder: (context, member) => [
        for (final text in [member.name, member.email])
          Padding(
            padding: EdgeInsets.all(context.spacing.space3),
            child: Text(text ?? "", overflow: TextOverflow.ellipsis),
          ),
      ],
    ),
  );
}

/// The selectable cards the touch layouts share, with plain cards: a tap
/// selects one card, and in select mode every card shows its check at its
/// corner.
@widgetbook.UseCase(name: "Default", type: SelectionCardList)
Widget selectionCardListUseCase(BuildContext context) {
  return selectableRowsStory(
    context,
    label: "Cards",
    make: storyMembers,
    identity: (member) => member.userId,
    selectable: (member) => MemberIdentifier(member.userId),
    traits: (_) => const [],
    windows: listWindows,
    builder: (rows) => SelectionCardList<skir.OrganizationMember>(
      rows: rows,
      selectableOf: (member) => MemberIdentifier(member.userId),
      labelOf: (member) => member.displayName,
      emptyBuilder: (context) => const EmptyState(
        icon: MaterialSymbols.groups_2_rounded,
        title: "Nothing to select",
        description: "Cards appear here once there are some.",
      ),
      contentBuilder: (context, member) =>
          PersonSummary(name: member.name, email: member.email),
    ),
  );
}
