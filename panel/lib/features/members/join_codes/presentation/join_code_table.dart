import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Desktop table presentation of active invitation codes.
///
/// Rows expose pointer and keyboard operations through
/// [JoinCodeTableRowShortcuts]. This widget owns focus and selection visuals,
/// while the route owns selection and providers supply observed data. Row
/// controls submit prepared repository commands through shared local work.
class JoinCodesTable extends HookConsumerWidget {
  const JoinCodesTable({required this.selection, super.key});

  final SelectableRows<skir.JoinCode> selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final codes = selection.rows.items;

    return SelectionTable<skir.JoinCode>(
      selection: selection,
      idOf: (code) => code.code,
      labels: const ["Join Code", "Type", "Expires"],
      hasScrollBody: false,
      columnWidths: const {
        0: FixedColumnWidth(48),
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
      rowBuilder: (context, entry) => _buildCodeRow(
        context,
        ref,
        entry.item,
        codes,
        selection.selectedIds.value.contains(entry.id),
        theme,
      ),
    );
  }

  TableRow _buildCodeRow(
    BuildContext context,
    WidgetRef ref,
    skir.JoinCode code,
    List<skir.JoinCode> codes,
    bool isSelected,
    ThemeData theme,
  ) {
    final fullUrl = joinCodeUrl(code.code);

    void toggleSelection() {
      if (isSelected) {
        selection.selectedIds.value = selection.selectedIds.value
            .where((selected) => selected != code.code)
            .toSet();
        return;
      }
      selection.selectedIds.value = {...selection.selectedIds.value, code.code};
    }

    Widget withShortcuts(Widget child, {RowRole role = RowRole.part}) =>
        JoinCodeTableRowShortcuts(
          code: code,
          onToggleSelection: toggleSelection,
          onSelectAll: () =>
              selection.selectedIds.value = codes.map((c) => c.code).toSet(),
          onClearSelection: () => selection.selectedIds.value = {},
          onCopy: () => _copyToClipboard(context, fullUrl),
          isSelected: isSelected,
          hasSelection: selection.selectedIds.value.isNotEmpty,
          rows: selection.rows,
          selectedIds: selection.selectedIds.value,
          // Inside the shortcuts, so they answer while the row is focused.
          child: RowStop(
            role: role,
            bounds: RingBounds.tableRow,
            borderRadius: context.shapes.mediumBorderRadius,
            label: role == RowRole.stop ? fullUrl : null,
            child: child,
          ),
        );

    return TableRow(
      key: ValueKey(code.code),
      decoration: BoxDecoration(
        // Fill means selected; the ring layer shows focus.
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.12)
            : Colors.transparent,
      ),
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.space2,
              vertical: context.spacing.space3,
            ),
            child: withShortcuts(
              role: RowRole.stop,
              // The row stop takes Space through the row's shortcuts.
              ExcludeFocus(
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => toggleSelection(),
                ),
              ),
            ),
          ),
        ),
        TableCell(
          child: withShortcuts(
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.spacing.space2,
                vertical: context.spacing.space3,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: BlurReveal(
                      blurSigma: 3,
                      child: SelectableText(
                        fullUrl,
                        style: theme.textTheme.bodyMedium!.copyWith(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: context.spacing.space2),
                  Button(
                    face: ButtonFace.icon,
                    icon: const Icon(Icons.copy, size: 16),
                    label: "Copy Join Code",
                    tooltip: "Copy Join Code",
                    onPressed: () => _copyToClipboard(context, fullUrl),
                  ),
                ],
              ),
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.space2,
              vertical: context.spacing.space3,
            ),
            child: JoinCodeTypeBadges(code: code),
          ),
        ),
        TableCell(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.space2,
              vertical: context.spacing.space3,
            ),
            child: CountdownBadge(
              endDate: code.expiresAt,
              onExpired: () {
                selection.selectedIds.value = selection.selectedIds.value
                    .where((selected) => selected != code.code)
                    .toSet();
              },
            ),
          ),
        ),
        TableCell(
          child: withShortcuts(
            JoinCodeRowActions(code: code, rows: selection.rows),
          ),
        ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    showSuccessSnackBar(context, "Join code copied to clipboard");
  }
}
