import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The active join codes as a table: the link with its Copy button, how
/// often it works, its expiry, and a revoke button on each row.
///
/// The table renders the rows [JoinCodesTab] owns. Each row selects through
/// the shared selection, so the inspector shows the selected codes.
class JoinCodesTable extends StatelessWidget {
  const JoinCodesTable({required this.rows, super.key});

  final AnimatedRows<skir.JoinCode> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cellPadding = EdgeInsets.symmetric(
      horizontal: context.spacing.space2,
      vertical: context.spacing.space3,
    );
    return SelectionTable<skir.JoinCode>(
      rows: rows,
      selectableOf: (code) => JoinCodeIdentifier(code.code),
      labelOf: (code) => joinCodeUrl(code.code),
      labels: const ["Join Code", "Type", "Expires"],
      hasScrollBody: false,
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(2),
        2: IntrinsicColumnWidth(),
        3: IntrinsicColumnWidth(),
        4: FixedColumnWidth(80),
      },
      emptyBuilder: (context) => const EmptyState(
        icon: MaterialSymbols.link_off_rounded,
        title: "No active join codes",
        description: "Generate a join code above to get started!",
      ),
      shortcutsOf: (code) => joinCodeRowShortcuts(code, rows),
      leadingBuilder: (context, code, selected) =>
          JoinCodeMark(selected: selected),
      cellsBuilder: (context, code) => [
        SelectionTableCell(
          Padding(
            padding: cellPadding,
            child: Row(
              children: [
                Expanded(
                  child: BlurReveal(
                    blurSigma: 3,
                    child: Text(
                      joinCodeUrl(code.code),
                      style: theme.textTheme.bodyMedium!.copyWith(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: context.spacing.space2),
                CommandButton(
                  command: joinCodeCopy(code),
                  face: ButtonFace.icon,
                  icon: const Icon(Icons.copy, size: 16),
                  label: "Copy Join Code",
                  doneLabel: "Copied",
                  tooltip: "Copy Join Code",
                ),
              ],
            ),
          ),
        ),
        SelectionTableCell(
          Padding(
            padding: cellPadding,
            child: JoinCodeTypeBadges(code: code),
          ),
        ),
        SelectionTableCell(
          Padding(
            padding: cellPadding,
            child: CountdownBadge(endDate: code.expiresAt),
          ),
        ),
        SelectionTableCell.controls(
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.spacing.space2),
            child: CommandButton(
              face: ButtonFace.icon,
              color: context.colors.danger,
              icon: const Icon(Icons.link_off, size: 20),
              label: "Revoke join code",
              command: joinCodeRowRevocation(code, rows),
            ),
          ),
        ),
      ],
    );
  }
}

/// The active join codes as cards for touch layouts: the link, its expiry
/// and how often it works. A tap selects the code, and the inspector shows
/// Copy and Revoke.
class JoinCodesCardList extends StatelessWidget {
  const JoinCodesCardList({required this.rows, super.key});

  final AnimatedRows<skir.JoinCode> rows;

  @override
  Widget build(BuildContext context) {
    return SelectionCardList<skir.JoinCode>(
      rows: rows,
      selectableOf: (code) => JoinCodeIdentifier(code.code),
      labelOf: (code) => joinCodeUrl(code.code),
      emptyBuilder: (context) => const EmptyState(
        icon: MaterialSymbols.link_off_rounded,
        title: "No active join codes",
        description: "Generate a join code above to get started!",
      ),
      shortcutsOf: (code) => joinCodeRowShortcuts(code, rows),
      contentBuilder: (context, code, selected) => Row(
        spacing: context.spacing.space3,
        children: [
          JoinCodeMark(selected: selected),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: context.spacing.space1,
              children: [
                BlurReveal(
                  blurSigma: 3,
                  child: Text(
                    joinCodeUrl(code.code),
                    style: Theme.of(context).textTheme.bodyMedium!
                        .copyWith(fontWeight: FontWeight.w500, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Wrap(
                  spacing: context.spacing.space1,
                  runSpacing: context.spacing.space1,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    CountdownBadge(endDate: code.expiresAt),
                    JoinCodeTypeBadges(code: code),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A join code's identity mark: a link tile that turns into a check while
/// the code is selected.
class JoinCodeMark extends StatelessWidget {
  const JoinCodeMark({required this.selected, super.key});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CircleAvatar(
      radius: 16,
      backgroundColor: selected
          ? context.colors.success
          : theme.colorScheme.primaryContainer,
      child: Icon(
        selected ? Icons.check : Icons.link,
        color: selected
            ? context.colors.onSuccess
            : theme.colorScheme.onPrimaryContainer,
        size: 18,
      ),
    );
  }
}

/// The commands of [code]'s row: C copies it, and holding Delete revokes
/// the selection when it holds the code, otherwise the code alone.
List<ActionShortcut> joinCodeRowShortcuts(
  skir.JoinCode code,
  AnimatedRows<skir.JoinCode> rows,
) => [joinCodeCopy(code), joinCodeRowRevocation(code, rows)];

/// The Revoke command of [code]'s row: its key and its button.
ActionShortcut joinCodeRowRevocation(
  skir.JoinCode code,
  AnimatedRows<skir.JoinCode> rows,
) {
  return joinCodeRevocation(
    id: "revoke_join_code_${code.code}",
    label: "Revoke join code",
    targets: (ref) => {
      for (final id
          in ref
              .selectionOrRow(JoinCodeIdentifier(code.code))
              .whereType<JoinCodeIdentifier>())
        id.codeId,
    },
    rows: rows,
  );
}
