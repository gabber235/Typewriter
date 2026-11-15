import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The active join codes as a table: the link with its Copy button, how
/// often it works, and its expiry.
///
/// The table renders the rows [JoinCodesTab] owns. Each row selects through
/// the shared selection, so the inspector shows the selected codes and
/// revokes them.
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
      },
      emptyBuilder: (context) => const EmptyState(
        icon: MaterialSymbols.link_off_rounded,
        title: "No active join codes",
        description: "Generate a join code above to get started!",
      ),
      leadingBuilder: (context, code) => const JoinCodeMark(),
      cellsBuilder: (context, code) => [
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
        Padding(
          padding: cellPadding,
          child: JoinCodeTypeBadges(code: code),
        ),
        Padding(
          padding: cellPadding,
          child: CountdownBadge(endDate: code.expiresAt),
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
      contentBuilder: (context, code) => Row(
        spacing: context.spacing.space3,
        children: [
          const JoinCodeMark(),
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

/// A join code's identity mark: a link tile. It stays the same while the
/// code is selected; the row's fill shows the selection, and in select mode
/// its [SelectorCheck] is the one check.
class JoinCodeMark extends StatelessWidget {
  const JoinCodeMark({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CircleAvatar(
      radius: 16,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Icones(
        MaterialSymbols.link_rounded,
        color: theme.colorScheme.onPrimaryContainer,
        size: 18,
      ),
    );
  }
}
